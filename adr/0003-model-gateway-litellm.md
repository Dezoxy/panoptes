# 0003. Run the model gateway on LiteLLM, configured as code

## Status

Accepted

## Date

2026-09-21

## Context

[0002. Hybrid topology and placement](0002-hybrid-topology-and-placement.md) fixes where the gateway
runs and why it must run outside any single cloud, but not what it is. The gateway is the only path
from a consumer to a model, so it carries routing, fallback, entitlement enforcement, quotas, cost
attribution and the audit record. Everything the controls plane and the FinOps layer claim rests on
that one component.

The provider set is fixed by placement: Azure AI Foundry deployments in the firm's own subscription,
Anthropic, OpenAI and self-hosted Ollama, and a consumer never holds a provider credential. Logging
is where this meets regulation. Prompt and completion bodies are personal data in most workloads and
MNPI in some, so what the gateway records by default is a data-protection decision, not an
implementation detail. [`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md) already
sets metadata-only as the default at every tier.

## Decision drivers

- **Multi-provider from day one.** Four providers, two external; a runtime treating non-native
  providers as a special case cannot express the chains.
- **Runnable outside Azure.** ADR-0002's exit-path reason fails if the control point is cloud-bound.
- **Per-request cost, attribution and entitlement.** Budgets in `../docs/finops/` are per consumer
  and only the gateway holds the token counts; entitlements are Entra groups, so a key maps to one.
- **Metadata-only audit by default.** Required by the tiering rubric, and cheaper to defend than a
  per-workload content-logging exemption.

## Considered options

1. LiteLLM in proxy mode, configured as code from `../gateway/`.
2. Azure API Management AI Gateway now.
3. A custom gateway written and maintained in-house.
4. A commercial AI gateway — Portkey, Kong AI Gateway or similar.
5. No gateway: each application uses provider SDKs directly.

## Decision

The model gateway runtime is **LiteLLM in proxy mode**, configured as code from `../gateway/` and
running on the on-prem cluster in the lab tier. It provides multi-provider routing across Azure AI
Foundry deployments, Anthropic, OpenAI and self-hosted Ollama; a declared fallback order; per-key
and per-team quotas and rate limits; virtual keys mapped to Entra ID group entitlements; and
audit-log emission over OpenTelemetry. Credentials are never in the config: they arrive as
Kubernetes secrets sourced from Azure Key Vault.

Default audit logging is **metadata only** — caller identity, team, model requested and model
served, route decision, policy result, token counts, cost, latency and timestamps. Bodies are not
logged unless a workload at tier 2 or above opts in with a DPIA reference recorded against it. Audit
records are exported on a schedule to immutable storage, an Azure Blob container with an
immutability policy; retention is set in a later ADR, not here.

Azure APIM AI Gateway stays the documented production alternative for a Microsoft-standardised
estate. A Terraform module stub for it lives in `../iac/` so the switch path is visible rather than
asserted; it arrives in Phase 1.

## Consequences

### Positive

- One control point owns routing, entitlement, quota and audit, so attribution is complete by
  construction, not reconciled afterwards.
- Configuration is reviewed as code: a routing or quota change is a pull request against
  `../gateway/`, under the same CODEOWNERS gate as everything else.
- Metadata-only by default keeps most workloads out of DPIA scope and makes content logging a
  visible, signed exception; the immutable export survives a compromise of the cluster that wrote
  it.

### Negative and accepted trade-offs

- LiteLLM is a fast-moving open-source project. Version pinning and a canary route are mandatory,
  not optional, and an upgrade is a change with a rollback plan.
- Metadata-only logging means a bad answer cannot be reconstructed from platform records; debugging
  a quality complaint needs the consumer's own copy of the exchange.
- The gateway is a single point of failure in the lab tier, and the two audit sinks — telemetry for
  operations, immutable blob for evidence — have to be reconciled, which is work nobody has yet.

## Rejected alternatives

### Option 2 — Azure APIM AI Gateway now

- **Why not** — strong token-limit and semantic-cache policies and native Entra integration, but an
  Azure-only runtime contradicts the exit-path reason in ADR-0002, external providers are
  second-class behind custom policies, and per-request cost is not transparent in the way the FinOps
  layer needs.
- **Revisit if** — the estate standardises on APIM for all APIs, or the lab tier is retired and the
  exit path is proven another way.

### Option 3 — a custom gateway

- **Why not** — full control and no upstream to track, but it is a security-critical component built
  and maintained alone, in the request path of every call, with authentication, quota accounting and
  protocol drift becoming our defects.
- **Revisit if** — LiteLLM's licence, maintenance or security posture changes materially and no
  comparable open-source runtime has replaced it.

### Option 4 — a commercial AI gateway (Portkey, Kong AI Gateway or similar)

- **Why not** — feature-rich, but each adds a vendor to TPRM scope with due diligence, a contract,
  an exit plan and a renewal, and prices per request, putting a variable cost on the control point.
- **Revisit if** — LiteLLM cannot meet an audit requirement one of these does, with that requirement
  written down before the comparison starts.

### Option 5 — direct provider SDKs per application, no gateway

- **Why not** — rejected outright: no single control point, so no entitlement enforcement, no
  attribution and no quotas, with provider credentials spread across every application.
- **Revisit if** — no condition. This is the assumption the platform exists to remove.

### Full content logging by default

- **Why not** — it puts prompt and completion bodies, including personal data and potentially MNPI,
  into platform storage for every workload, needing a DPIA each and a retention position the firm
  has not taken.
- **Revisit if** — never as a default. It stays opt-in per workload, tier 2 or above, with a DPIA
  reference.

## Risks

- **A LiteLLM upgrade breaks a route or silently changes fallback behaviour.** Detectable by the
  canary route and fallback-rate metrics; mitigated by pinning and the provider-change playbook due
  in `../runbooks/`.
- **The single gateway instance fails and takes every route with it.** Detectable immediately; no HA
  in the lab tier by design.
- **Content logging is enabled without a DPIA reference, or the export drifts from the telemetry
  record.** Detectable as a config diff in `../gateway/`, and by record-count reconciliation between
  blob and audit stream.

## Related

- **Requirements** — [`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md),
  `../gateway/`
- **Other ADRs** — [0001](0001-record-architecture-decisions.md),
  [0002](0002-hybrid-topology-and-placement.md), [0004](0004-ci-on-github-actions.md)
