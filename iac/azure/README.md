# Azure root module

- **Owner** — AI Platform / Security
- **Status** — Draft
- **Last reviewed** — 2026-09-22
- **Out of scope** — the on-prem Kubernetes manifests, which are Documented per
  [ADR-0005](../../adr/0005-lab-tier-on-azure.md) rather than deployed anywhere; the
  gateway application itself, which lives in `../../gateway/`.

Terraform for the Panoptes Azure lab subscription (ADR-0002, ADR-0005): Sweden Central
primary, West Europe as the documented failover, on Azure Container Apps.

## What this manages today

- The lab resource group (`azurerm_resource_group`).
- A subscription-wide consumption budget with alerts at 50% and 90% actual spend and
  100% forecast spend (`azurerm_consumption_budget_subscription`).
- A tag policy assignment on the resource group, denying a resource that is missing
  any of the five mandatory tags (`policy.tf`).
- Key Vault, RBAC-authorised, with the signed-in operator granted `Key Vault Secrets
  Officer` (`keyvault.tf`).
- The Azure AI Foundry account and its model deployment (gpt-4o, regional Standard), Sweden Central; a second deployment follows the pending quota request
  (`foundry.tf`). See the secrets table below for where the key and endpoint land.
- Log Analytics, workspace-based Application Insights and the Azure Monitor managed
  Prometheus workspace (`observability.tf`).
- Three Entra ID security groups standing in for consumer teams, and the
  `panoptes-gateway` app registration with its `Gateway.Consumer` app role
  (`entra.tf`).
- The Container Apps environment, Consumption-only, bound to the Log Analytics
  workspace; the Container Apps PostgreSQL add-on (development tier, ADR-0005 — not
  for production data); and the `panoptes-gateway` Container App, with a
  user-assigned identity, an OpenTelemetry collector sidecar, and Key Vault
  references for its secrets (`container_apps.tf`).
- The gateway's own Container Registry, Basic SKU, admin account disabled
  (`container_apps.tf`); the `github-actions-panoptes` app registration and its two
  GitHub OIDC federated credentials, one per GitHub Actions trigger this repository
  uses (`github_actions.tf`). See "No static credentials" below.

Public network access is enabled on Key Vault and the Foundry account for this step,
each with a `#checkov:skip` recording why: the production placement (ADR-0002) uses a
private endpoint, which the on-prem gateway cannot reach until it runs inside the
Azure VNet.

## Key Vault secrets

| Secret | Written by | Read by |
| --- | --- | --- |
| `foundry-api-key` | `foundry.tf`, from the Foundry account's primary key | LiteLLM, in the gateway Container App |
| `foundry-endpoint` | `foundry.tf`, from the Foundry account | Not read by the gateway directly — `container_apps.tf` passes the endpoint into `AZURE_API_BASE` from the resource attribute, not this secret |
| `appinsights-connection-string` | `observability.tf`, from the Application Insights resource | The gateway's OpenTelemetry collector sidecar |
| `litellm-master-key` | `container_apps.tf`, generated with `random_password` | LiteLLM, in the gateway Container App |
| `admin-initial-password` | `operators.tf`, generated with `random_password` | The operator, once, setting up the work admin account — see "Operator identities" below |
| `anthropic-api-key` | **The operator, by hand** — never Terraform | LiteLLM, in the gateway Container App |
| `openai-api-key` | **The operator, by hand** — never Terraform | LiteLLM, in the gateway Container App |
| `openrouter-api-key` | **The operator, by hand** — never Terraform | LiteLLM, in the gateway Container App |

The three operator-supplied secrets are referenced by URL only — this module never
reads or creates their values. Write them once, after `kv-panoptes-lab-swc` exists,
with the actual key pasted in place of `<paste>`:

```sh
az keyvault secret set --vault-name kv-panoptes-lab-swc --name anthropic-api-key --value "<paste>"
az keyvault secret set --vault-name kv-panoptes-lab-swc --name openai-api-key --value "<paste>"
az keyvault secret set --vault-name kv-panoptes-lab-swc --name openrouter-api-key --value "<paste>"
```

### Gateway identity and role ordering

The gateway Container App runs with a **user-assigned managed identity**
(`id-panoptes-gateway-lab-swc`) rather than a system-assigned one. A system-assigned
identity only exists once the app does, so its `AcrPull` and `Key Vault Secrets User`
roles could only be granted after creation; the first revision could neither pull the
image nor resolve its Key Vault references, and provisioning hung until it timed out.
With a user-assigned identity the roles are granted first and the app is created after
them (`depends_on`), so no restart step exists. Role propagation can still lag by a
minute on a fresh assignment; a second `make apply` after that is the only remedy ever
needed.

## Azure CLI profile

The Makefile sets `AZURE_CONFIG_DIR=~/.azure-panoptes`, so every target uses a CLI login
that belongs to Panoptes alone. Other Azure work on the same machine uses the default
profile and cannot move the account Terraform acts as. Sign in once with `make login`.
Running `az` by hand for this estate needs the same variable exported. The providers are
also pinned to the tenant, so a mismatched login fails at `init` rather than acting
elsewhere.

## Operator identities

Two operator accounts exist in this tenant (`operators.tf`):

- **Break-glass** — the personal Microsoft account `azure@tomhorvath.me`. Billing
  owner and Global Administrator. Not used for day-to-day administration; kept
  signed out except when the work account is unavailable.
- **Work admin** — `admin@azuretomhorvath.onmicrosoft.com` ("Panoptes Platform
  Administrator"), Global Administrator and subscription Owner, used for daily
  administration going forward. Its object id feeds `local.platform_operators`
  alongside break-glass's, so both hold the same Key Vault and platform-group
  grants — see the header comment in `operators.tf`.

Both are standing (non-PIM) role assignments: PIM-eligible assignment is the
production alternative (`operators.tf`'s comment on
`azuread_directory_role_assignment.admin_global_administrator`), not available on
this tenant's licence.

First sign-in for the work admin account, after `make apply` has created it:

1. Retrieve the initial password once:

   ```sh
   az keyvault secret show --vault-name kv-panoptes-lab-swc --name admin-initial-password --query value -o tsv
   ```

2. Sign in at <https://portal.azure.com> as `admin@azuretomhorvath.onmicrosoft.com`
   with that password.
3. Change the password when prompted (`force_password_change` is set on the user).
4. Register MFA.
5. Switch the CLI to the work account and confirm it lands on the right tenant:

   ```sh
   az logout
   az login --tenant 00f1b6c6-e44f-42cd-95fd-d0fd61c67825
   ```

6. Disable the Key Vault secret version now that it has been read and the password
   changed — it is not rotated, only retired:

   ```sh
   az keyvault secret set-attributes --vault-name kv-panoptes-lab-swc --name admin-initial-password --enabled false
   ```

## No static credentials in the image path

The gateway image is not public, and the registry has no admin password (owner
decision — supersedes an earlier plan to pull a public `ghcr.io` image). Nothing in
the image's build-to-run path is a stored secret:

- **Pull** — the gateway's user-assigned identity has `AcrPull` on
  `crpanopteslabswc` (`azurerm_role_assignment.gateway_acr_pull`), referenced in the
  app's `registries` block by identity, not by username and password.
- **Push** — GitHub Actions authenticates to Azure with
  [workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation):
  the `github-actions-panoptes` app registration trusts GitHub's own OIDC tokens for
  this repository (one federated credential, for pushes to `main` only; pull-request
  runs build without pushing and hold no identity — `github_actions.tf`), and its
  service principal has `AcrPush`
  on the registry, nothing more. No client secret, no publish profile, no registry
  password is generated or stored anywhere.

A `terraform plan` from CI (needing a `Reader` role) is a later step, deliberately not
granted yet — see the comment in `github_actions.tf`.

### Repository variables the GitHub Actions workflow needs

Three **variables** (not secrets — none of these are sensitive on their own; the OIDC
exchange is what actually authenticates):

| Variable | Value |
| --- | --- |
| `AZURE_CLIENT_ID` | This module's `github_actions_client_id` output |
| `AZURE_TENANT_ID` | The subscription's tenant id (`az account show --query tenantId -o tsv`) |
| `AZURE_SUBSCRIPTION_ID` | `f82dcc06-8cd5-4644-bae4-73ce992da90c` (`sub-panoptes-lab`) |

```sh
gh variable set AZURE_CLIENT_ID --repo Dezoxy/panoptes --body "$(terraform output -raw github_actions_client_id)"
gh variable set AZURE_TENANT_ID --repo Dezoxy/panoptes --body "$(az account show --query tenantId -o tsv)"
gh variable set AZURE_SUBSCRIPTION_ID --repo Dezoxy/panoptes --body "f82dcc06-8cd5-4644-bae4-73ce992da90c"
```

## What later steps add

The Ollama Container App (self-hosted model, CPU only); the Grafana Container App; the
`panoptes-meter` scheduled job. See ADR-0005 for the full placement.

## Bootstrap and init sequence

State lives in Azure Storage, addressed with Entra ID (`use_azuread_auth = true`, no
storage account keys). The storage account cannot be a Terraform resource — Terraform
needs it to exist before it can store anything — so it is created once by a script.

1. **Once per subscription** — create the state backend:

   ```sh
   SUBSCRIPTION_ID=<guid> make bootstrap
   ```

   Creates the state resource group, storage account and container, registers the
   resource providers Phase 1 needs, and writes `lab.tfbackend` (gitignored) with the
   backend values so nothing is copied by hand. Rerunning it is safe. Run the script
   with `--dry-run` to see the `az` commands before anything is created.

2. **Initialise** against the backend file:

   ```sh
   make init
   ```

3. **Plan**, saved to `lab.tfplan` (gitignored) so apply runs exactly what was read:

   ```sh
   make plan
   ```

4. **Apply is run by the platform owner, locally, after reading the plan** (`make apply`). Never from
   CI — ADR-0004 keeps CI read-only, and the working rule in `CLAUDE.md` is that
   nothing is deployed on this platform's behalf without a human reading the plan
   first.

Copy `lab.auto.tfvars.example` to `lab.auto.tfvars` (gitignored — `*.tfvars`) and fill
in `subscription_id` and `alert_emails` before running `plan`.

## Naming convention

Cloud Adoption Framework style: `<resource-type>-<workload>-<environment>-<region>`.
Storage accounts and container registries cannot take hyphens: storage accounts follow
`st<workload><purpose><8-char-hash>` instead, with the hash derived from the
subscription id so the globally-unique name stays reproducible without being
guessable; the registry follows `cr<workload><environment><region>` (no hash needed —
the name is already globally unique enough for the lab's single subscription).

| Region | Code |
| --- | --- |
| Sweden Central | `swc` |
| West Europe | `weu` |

| Resource | Example name |
| --- | --- |
| Resource group | `rg-panoptes-lab-swc` |
| Key Vault | `kv-panoptes-lab-swc` |
| Container Apps environment | `cae-panoptes-lab-swc` |
| Container App (gateway) | `ca-panoptes-gateway-lab-swc` |
| Container App (Postgres add-on) | `ca-panoptes-postgres-lab-swc` |
| Container Registry | `crpanopteslabswc` |
| Terraform state storage account | `stpanoptesstate<8-char-hash>` |

## Tags

Every resource this module creates carries all five:

| Tag | Value |
| --- | --- |
| `workload` | `panoptes` |
| `environment` | `lab` |
| `owner` | `ai-platform` |
| `cost-centre` | `platform-lab` |
| `managed-by` | `terraform` |

`policy.tf` enforces this inside the resource group; nothing here checks the state
resource group `bootstrap.sh` creates, which is tagged by the script itself instead.

## `always_on`

A Terraform variable, default `false`. It sets the gateway Container App's minimum
replicas to one when responsiveness matters — a measurement window or a review session — and back
to zero the rest of the time (ADR-0005: cold starts distort latency numbers, so this
is a deliberate, temporary switch, not a standing setting). It will also cover Grafana
once that Container App exists.

```sh
terraform plan -var=always_on=true
```
