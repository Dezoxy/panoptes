# 0005. Run the lab tier on Azure Container Apps

## Status

Accepted

Amends [0002. Hybrid topology and placement](0002-hybrid-topology-and-placement.md)

## Date

2026-09-22

## Context

[0002](0002-hybrid-topology-and-placement.md) placed the lab tier — gateway runtime, self-hosted
model, observability stack — on the on-prem Kubernetes cluster. That cluster is not running today,
and waiting for it delays Phase 1, which is the gateway itself. Nothing else has changed: the estate
is Microsoft-centred, identity is Entra ID, and tier 3 in
[`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md) still narrows Restricted data to
own-tenancy or self-hosted models.

The second constraint is imposed rather than chosen: the Azure lab subscription carries a 200 USD
credit expiring on 2026-10-22 and a **30 EUR monthly cap** after that. The original observability
stack does not fit. An always-on Container Apps replica at 0.5 vCPU and 1 GiB is roughly 13 USD a
month, so self-hosted Loki, Tempo and Prometheus need one each — about 26 EUR a month idle, before a
token is bought — and Azure Managed Grafana Standard is well over 100 USD a month on its own.

## Decision drivers

- **Phase 1 must be able to start.** A placement waiting on hardware nobody has racked is a plan.
- **The 30 EUR cap is a constraint, not a preference.** Model tokens come out of the same envelope.
- **Tier 3 routing stays provable, under Entra-native identity and secrets.** The own-tenancy rule,
  Entra groups for entitlements and Key Vault for secrets are all unchanged.
- **The exit path must stay real.** `../docs/vendors/` requires an exit plan the gateway can honour,
  and ADR-0002 made "the gateway already runs outside Azure" the proof of it.

## Considered options

1. Azure Container Apps on the consumption plan, scale-to-zero, with Azure-native observability.
2. Keep the on-prem k3s cluster as the lab tier, as ADR-0002 wrote it.
3. One burstable Azure VM running Docker Compose.
4. Container Apps, with self-hosted Loki, Tempo and Prometheus as always-on replicas.
5. Container Apps, with Azure Managed Grafana rather than a self-hosted Grafana.
6. AKS for the lab tier.

## Decision

The lab tier runs in the **Azure lab subscription, Sweden Central, on Azure Container Apps**, on the
consumption plan, scaling to zero by default. A Terraform variable `always_on` sets minimum replicas
to one for the gateway and Grafana when responsiveness matters, and back to zero afterwards.
`panoptes-gateway` runs as a Container App, with the **Container Apps PostgreSQL add-on on the
development tier** as its database for LiteLLM virtual keys, teams and spend logs; it is not for
production data. The self-hosted model is **Ollama as a scale-to-zero Container App, CPU only, with
the model baked into the image** — still own-tenancy, so the tier 3 provider rule is unchanged.

Observability is Azure-native. An **OpenTelemetry collector runs as a sidecar of the gateway**; logs
and traces go to **Application Insights** over a Log Analytics workspace, metrics to **Azure Monitor
managed Prometheus** by remote write, and **Grafana is a scale-to-zero Container App** reading both
through a managed identity. `panoptes-meter` is a **scheduled Container Apps job** turning LiteLLM
spend logs into cost metrics. Application Insights sampling is **off**: a sampled-away audit record
is not an audit record. The control plane is unchanged from ADR-0002 — Key Vault, two Foundry
deployments in Sweden Central, Entra app registrations, a 30 EUR budget with alerts at 15 and 27
EUR, a storage account for Terraform state bootstrapped once, West Europe as the documented
secondary. The exit path is now proven by construction rather than by continuous operation: the same
images run from a Compose file in `../gateway/` on any Docker host, and the Kubernetes manifests in
`../iac/` stay at **Documented** until an on-prem cluster exists. The on-prem tier is no longer the
lab tier but the **documented exit environment**.

## Consequences

### Positive

- Lab and production now share the same service — Container Apps was already ADR-0002's production
  target — so lab config is production config, and the placement-drift risk ADR-0002 accepted
  shrinks.
- Phase 1 starts without hardware, an idle month costs close to nothing, and Azure-native stores
  save roughly 26 EUR a month of always-on observability.

### Negative and accepted trade-offs

- **The exit-path story is weaker.** ADR-0002 exercised it continuously by running the control point
  outside Azure; it is now proven by construction — a Compose file and manifests that nobody runs.
- **The self-hosted Loki, Tempo and Grafana stack is replaced in the lab by Azure-native stores.**
  Those containers stay in the model, marked documented, as the answer if the lab has to hold an
  audit query Azure-native stores cannot — and leaving Azure now means moving the telemetry too.

## Rejected alternatives

### Option 2 — keep the on-prem k3s cluster as the lab tier

- **Why not** — the cluster is not running, so this delays Phase 1 for hardware, and a single node
  adds operational weight for the same proof a Container App gives without any of it.
- **Revisit if** — the cluster comes up; it then becomes the exit-path test, with the Compose file
  and the manifests exercised there — a stronger proof than either placement gives alone.

### Option 3 — one burstable Azure VM running Docker Compose

- **Why not** — closest to the homelab pattern, but a size that fits is about 25 EUR a month, always
  on, leaving nothing for tokens, and it builds no Container Apps or Azure Monitor experience.
- **Revisit if** — Container Apps cold start or an add-on limit blocks a test the lab needs to run.

### Option 4 — self-hosted Loki, Tempo and Prometheus as always-on Container Apps

- **Why not** — it matches the original plan and keeps the stores portable, but three always-on
  replicas are about 26 EUR a month idle: the whole cap before any model call.
- **Revisit if** — the cap rises to roughly 60 EUR, or an audit query the evidence needs cannot be
  answered from the Azure-native stores.

### Option 5 — Azure Managed Grafana

- **Why not** — managed and Entra-integrated, but Standard tier pricing exceeds the entire monthly
  cap, and the Essential tier is deprecated and takes no new workspaces.
- **Revisit if** — the estate standardises on it and cost stops being the lab's binding constraint.

### Option 6 — AKS for the lab tier

- **Why not** — ADR-0002 rejected AKS as the production placement for scheduling one container plus
  config; a cluster to run, upgrade and secure for a lab is a worse trade, not a better one.
- **Revisit if** — ADR-0002's triggers are met: custom networking or a CNI requirement, a
  sidecar-heavy mesh, or more than roughly five services needing a shared scheduler.

## Risks

- **Cold starts distort latency numbers.** Mitigated by setting `always_on` for measurement windows,
  and by reporting every latency figure with the replica state it was taken under.
- **The Postgres add-on is development tier: no SLA, no backups by default.** Nothing in it is a
  system of record — virtual keys are re-creatable from `../gateway/`, and spend logs feed metering,
  not the audit record. Detectable as a metering job that finds no rows.
- **Application Insights sampling silently drops audit records.** Sampling is off by design;
  detectable by record-count reconciliation between the gateway's counters and the workspace.
- **The credit expires on 2026-10-22 and spend runs past the cap.** Detectable by the budget alerts
  at 15 and 27 EUR, which are the guard on this decision rather than a report about it.

## Related

- **Requirements** — [`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md),
  `../docs/vendors/`, `../gateway/`
- **Architecture views** — `../docs/architecture/model/deployment.dsl`
- **Other ADRs** — [0002](0002-hybrid-topology-and-placement.md),
  [0003](0003-model-gateway-litellm.md)
