# 0002. Run a hybrid topology with the control plane in Azure and the gateway on-prem

## Status

Accepted

Amended by [0005. Lab tier on Azure](0005-lab-tier-on-azure.md)

## Date

2026-09-21

## Context

Northgate Asset Management is Microsoft-centred: identity is Entra ID, the Copilot estate is
Microsoft 365, and Azure is the production target. Panoptes must sit inside that without becoming
inseparable from it: the gateway is the single control point every model call passes through, and
one that can only exist inside a single cloud disappears the day that cloud is exited.

Two constraints are imposed, not chosen: model data stays in the EU, narrowed by tier 3 in
[`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md) to own-tenancy or self-hosted
models; and authentication is Entra ID. Against those: one operator, intermittent traffic, an
on-prem cluster with no GPU, and no production tenant.

## Decision drivers

- **Tier 3 routing must be provable.** Restricted data needs a model that never leaves Northgate
  infrastructure; EU residency is regulatory, not negotiable.
- **Entra-native identity and secrets.** Entitlements are Entra groups; secrets are Key Vault.
- **The exit path must be exercised, not asserted.** `../docs/vendors/` requires an exit plan per
  provider; one the gateway cannot honour is a document, not a control.
- **Somewhere for changes to land first, at a run rate suiting intermittent traffic.** Everything in
  the catalogue is at Discovery; cost is a preference here, not a requirement.

## Considered options

1. Hybrid: control plane in Azure, gateway runtime and self-hosted model on-prem.
2. Everything in Azure.
3. Everything on-prem.
4. Hybrid with a single Azure region rather than a documented failover pair.
5. Hybrid, with vLLM on GPU as the self-hosted runtime now.
6. Hybrid, with AKS rather than Azure Container Apps as the documented production placement.

## Decision

Placement is hybrid. The Azure subscription holds the control plane: Entra ID for identity, Key
Vault for secrets, Azure AI Foundry for hosted model deployments. External providers — Anthropic and
OpenAI — are reached only through the gateway, never directly by a consumer. The on-prem Kubernetes
cluster runs the gateway runtime, the self-hosted model and the observability stack as the **LAB
tier**, and admin-plane access is through a zero-trust access proxy, not a network perimeter. Azure
regions are **Sweden Central primary, West Europe secondary** — Sweden Central for model
availability, West Europe as the documented failover, both EU. Production placement for the gateway
runtime is **Azure Container Apps first**, with AKS as the alternative; the self-hosted runtime is
**Ollama, CPU-only**.

The on-prem lab tier exists for three reasons, all of which must hold for it to stay:

1. **It is a lab tier by design.** Changes land there first; Azure is the production target.
2. **It is the provider-neutral exit path.** The control point must be able to run outside any
   single cloud, so exiting a cloud or a provider does not remove the thing governing the others.
3. **It gives data-residency control.** Restricted classes route to a model that never leaves the
   firm's own infrastructure — the tier 3 rule: own-tenancy only, meaning Foundry in the firm's
   subscription or self-hosted.

Moving from Container Apps to AKS is triggered by any one of: custom networking or a bring-your-own
CNI; a sidecar-heavy service mesh; more than roughly five platform services needing a shared
scheduler.

## Consequences

### Positive

- Tier 3 routing is demonstrable, not promised: a Restricted call reaches a model on Northgate
  hardware and the audit record shows it.
- The exit path is exercised continuously, because the gateway already runs outside Azure, and
  identity, secrets and hosted models stay where the firm already operates them.

### Negative and accepted trade-offs

- The lab tier is not the production target and will drift from it: two runtimes, two sets of
  failure modes.
- The single lab node has no high availability. A reboot takes the gateway, the self-hosted model
  and the observability stack with it, and no HA is planned there.
- CPU-only Ollama latency is poor — seconds, not milliseconds. It proves the route, the policy and
  the exit path, nothing more. West Europe is likewise a written failover position until one is
  rehearsed.

## Rejected alternatives

### Option 2 — everything in Azure

- **Why not** — it removes the exit-path proof: the control point would live inside the cloud it
  must be able to leave. It also merges the lab tier into the production target, and pays always-on
  compute.
- **Revisit if** — a production tenant exists and the lab tier is retired; the exit path then needs
  a different proof.

### Option 3 — everything on-prem

- **Why not** — no Azure AI Foundry, so no own-tenancy hosted models and no tier 3 provider set
  beyond one self-hosted runtime. Entra-native identity and Key Vault would need self-operated
  equivalents, contradicting the Microsoft-centred estate.
- **Revisit if** — never in practice: it would mean the firm leaving Entra ID, a whole-estate
  decision this platform would not drive.

### Option 4 — a single Azure region

- **Why not** — cheaper and simpler, but model availability differs between the regions, and one
  region leaves a residency-constrained platform with no answer when a model is withdrawn.
- **Revisit if** — West Europe's model availability catches up with Sweden Central *and* the
  failover requirement is dropped. Both, not either.

### Option 5 — vLLM on GPU as the self-hosted runtime now

- **Why not** — there is no GPU on the lab node. vLLM is the documented production answer, but
  running it now means buying hardware to speed up a route whose purpose is to prove it exists.
- **Revisit if** — a GPU becomes available on the lab node, or self-hosted latency blocks a tier 3
  pilot from finishing its eight-week window.

### Option 6 — AKS as the documented production placement

- **Why not** — a cluster to run, upgrade and secure in exchange for scheduling one container plus
  config; Container Apps does the same with scale-to-zero.
- **Revisit if** — any trigger above is met: custom networking or a CNI requirement, a sidecar-heavy
  mesh, or more than roughly five services needing a shared scheduler.

## Risks

- **The lab tier drifts from the production target.** Detectable by the docs-to-IaC drift check
  planned in `../checks/`, and by a Container Apps deployment failing on config the cluster allowed.
- **The single lab node fails and takes everything with it.** No mitigation by design; the SLOs in
  `../slos/` must not claim one.
- **Ollama latency makes the tier 3 route unusable.** Detectable as latency percentiles on the
  self-hosted route, and as a pilot that cannot finish its window.

## Related

- **Architecture views** — `../docs/architecture/model/deployment.dsl`
- **Requirements** — [`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md),
  `../docs/vendors/`
- **Other ADRs** — [0001](0001-record-architecture-decisions.md),
  [0003](0003-model-gateway-litellm.md), [0004](0004-ci-on-github-actions.md)
