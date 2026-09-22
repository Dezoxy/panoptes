# Gateway

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-22
- **Out of scope** — the provider contracts behind the routes (`docs/vendors/`), the
  policy rules the gateway evaluates (`policies/`), and the infrastructure it runs on
  (`iac/`).

Configuration for `panoptes-gateway`: routing rules, the provider and model catalogue,
fallback chains, per-consumer quotas and rate limits, and the request and response
transforms applied at the edge. Every consumer call to a model passes through here, so
this directory is also where the audit trail is defined — what is recorded on each call
and what is deliberately not.

Nothing here is a secret. Provider credentials live in Key Vault and are referenced,
never committed; `gitleaks` runs on this path like every other.

## What runs

`panoptes-gateway` is [LiteLLM](https://docs.litellm.ai/) in proxy mode
([ADR-0003](../adr/0003-model-gateway-litellm.md)), on Azure Container Apps
([ADR-0005](../adr/0005-lab-tier-on-azure.md)), with an OpenTelemetry collector sidecar
exporting traces and logs to Application Insights. `gateway/config.yaml` is the routing
table, fallback chains, JWT auth and logging config, baked into the image at
`gateway/Dockerfile`; `gateway/otel/collector.yaml` is the sidecar's config.

## Route table

| Alias | Provider | Data class max | Tier max | Residency | Fallback role |
| --- | --- | --- | --- | --- | --- |
| `azure-gpt-4o` | Azure AI Foundry (own tenant, `gpt-4o`) | Restricted | 3 | eu-sweden-central | Primary for `chat-default` and `chat-restricted` |
| `anthropic-claude-sonnet` | Anthropic | Confidential (vendor record pending) | 2 | vendor-us | Fallback 2 for `chat-default` |
| `openai-gpt-small` | OpenAI | Confidential (vendor record pending) | 2 | vendor-us | Fallback 1 for `chat-default` |
| `openrouter-mistral` | OpenRouter (broker) | Internal | 1 | broker | Not in a fallback chain |
| `ollama-llama3.2` | Self-hosted Ollama | Restricted | 3 | own-tenancy | Fallback for `chat-restricted` |
| `chat-default` | Azure AI Foundry (alias of `azure-gpt-4o`) | Restricted | 3 | eu-sweden-central | Group entry point — falls back to `openai-gpt-small`, then `anthropic-claude-sonnet` |
| `chat-restricted` | Azure AI Foundry (alias of `azure-gpt-4o`) | Restricted | 3 | eu-sweden-central | Group entry point — falls back to `ollama-llama3.2` only |

`chat-restricted` never falls back outside the firm's own tenancy: both its own
deployment and every route in its fallback chain sit at `eu-sweden-central` or
`own-tenancy`. `gateway/tests/test_config.py` enforces that as a config invariant, not
just a convention.

`anthropic-claude-sonnet` and `openai-gpt-small` are capped at Confidential, not
Restricted, because no vendor record for either provider exists yet in
`docs/vendors/` (Phase 3 scope) — see
[`docs/onboarding/platform-responsibility-matrix.md`](../docs/onboarding/platform-responsibility-matrix.md)
layer 3. `openrouter-mistral` is capped at Internal because OpenRouter is a broker: it
forwards a request to a third-party model host of its own choosing, which is not a named,
reviewable vendor.

## Auth

Two credential types reach the gateway, both documented so neither is a provider API key
held by an application (forbidden — see the responsibility matrix):

- **JWT, for applications.** `general_settings.enable_jwt_auth` is on. Tokens are issued
  by Entra ID for the gateway app registration (tenant
  `00f1b6c6-e44f-42cd-95fd-d0fd61c67825`, client id
  `33dd8a55-b97f-4111-88cc-e7b370d51beb`, audience
  `api://00f1b6c6-e44f-42cd-95fd-d0fd61c67825/panoptes-gateway`). The `groups` claim maps
  to LiteLLM team ids and `oid` maps to the LiteLLM user id — see
  `general_settings.litellm_jwtauth` in `gateway/config.yaml`. Team ids are the object ids
  of the `sg-panoptes-research`, `sg-panoptes-client-reporting` and `sg-panoptes-platform`
  Entra groups; teams are registered in LiteLLM by the platform CLI, which arrives in
  Phase 1 step 5. Until then, a token from an unregistered team authenticates but has no
  team-scoped budget or model access.
- **Virtual keys, for scripts.** Issued by the platform, not self-served, and scoped to a
  team the same way a JWT's `groups` claim is. Also arrives with the Phase 1 step 5 CLI
  work.

## Logging mode

Metadata only, by default and currently without exception
(`litellm_settings.turn_off_message_logging: true`) — caller identity, team, model
requested and served, route decision, token counts, cost, latency and timestamps, not
prompt or completion bodies. This is the ADR-0003 default; enabling content logging for a
tier 2+ workload with a DPIA reference is a decision recorded on that workload, not a
change to this file.

## Running the exit-path stack

`gateway/compose.yaml` is the proof, not just the description, of ADR-0005's exit path:
the same three images that run as Container Apps in the lab tier run here, on any Docker
host.

```console
cp gateway/.env.example gateway/.env   # fill in the values you need to exercise
docker compose -f gateway/compose.yaml up --build
```

`gateway/.env` is gitignored; every value in `.env.example` is blank. `docker compose -f
gateway/compose.yaml config` renders cleanly with no `.env` file at all — every variable
defaults to empty — but the `otel-collector` service fails fast on a genuinely empty
`APPLICATIONINSIGHTS_CONNECTION_STRING` (the exporter validates it at startup, by design:
telemetry silently dropped is worse than a container that will not start), so running the
full stack needs at least a syntactically valid connection string. `litellm` itself needs
a real `postgresql://` `DATABASE_URL` — LiteLLM's database features do not support
SQLite or another engine.

## How the image is built

`gateway/Dockerfile` extends the pinned upstream image
(`ghcr.io/berriai/litellm:v1.102.0`) with `gateway/config.yaml` baked in, and runs as the
base image's non-root `nonroot` account. `.github/workflows/gateway-image.yml` builds it
on every change under `gateway/**`; a pull request builds only, a push to `main` also
pushes `crpanopteslabswc.azurecr.io/panoptes-gateway:sha-<short-sha>` and `:main` to
Azure Container Registry.

The image lives in ACR, not a public GHCR package: CI authenticates to Azure with GitHub
OIDC (workload identity federation) against an Entra app registration provisioned in
`iac/azure`, so no static registry credential ever exists in this path — not in GitHub,
not in the image, not in Key Vault. `az acr login` exchanges the federated token for a
short-lived ACR session. The Container App pulls the image the same way, with its own
managed identity holding the `AcrPull` role on the registry; nothing the platform holds is
a shared secret either direction.

## What the operator puts in Key Vault

The platform never handles these values directly — they are set in Key Vault by whoever
holds them, and reach the container only as environment variables `iac/azure` wires up.

| Key Vault secret | Delivered to the container as |
| --- | --- |
| `foundry-api-key` | `AZURE_API_KEY` |
| `appinsights-connection-string` | `APPLICATIONINSIGHTS_CONNECTION_STRING` |
| `anthropic-api-key` | `ANTHROPIC_API_KEY` |
| `openai-api-key` | `OPENAI_API_KEY` |
| `openrouter-api-key` | `OPENROUTER_API_KEY` |
| `litellm-master-key` | `LITELLM_MASTER_KEY` |

`AZURE_API_BASE` and `OLLAMA_API_BASE` are endpoints, not secrets, and `DATABASE_URL`
comes from the Container Apps PostgreSQL add-on binding rather than a Key Vault secret an
operator sets by hand; all three are still environment-only — never written into
`gateway/config.yaml`.

Arrives in **Phase 1**, with the gateway itself. It is the first thing that runs.
