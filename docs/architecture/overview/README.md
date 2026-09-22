## Architecture Overview

### Purpose

Panoptes gives Northgate Asset Management one way in to a model, one place that
decides what a consumer may do, and one record of what it did and what it cost.
Without it, each team reaches a provider on its own: separate keys, separate
contracts, no shared view of spend, and no way to answer which data class went
to which model.

The gateway is the only path to a provider. That is the constraint the rest of
the platform depends on — entitlement checks, cost attribution and audit records
all exist because every call passes through one place.

![System context view: who uses Panoptes, and what it depends on](embed:SystemContext)

### Layers

Seven layers. The first five hold the containers Panoptes builds and runs; the
last two are outside the system boundary.

| Layer | What it does | Containers |
| --- | --- | --- |
| Model gateway | Routing, fallback, per-key quotas, rate limits, audit records | `panoptes-gateway`, Gateway config store |
| Controls plane | Decides what a consumer may do, and holds the evidence that it decided | `panoptes-policies`, Entitlement source, Secret store, Evidence collector |
| Telemetry and FinOps | Records what happened and what it cost | `panoptes-meter`, OpenTelemetry collector, Grafana; Loki and Tempo documented only |
| Lifecycle | Governs how a workload gets in, and out | `panoptes` CLI, Onboarding register |
| Consumer surfaces | What a consumer reads and requests through | Self-service portal, Developer documentation site |
| Providers | Where the models actually run | Azure AI Foundry, Anthropic, OpenAI, self-hosted runtime |
| Copilot estate | Administered rather than built | Microsoft 365 Copilot, GitHub Copilot, Copilot Studio |

![Containers view: the building blocks of Panoptes, layer by layer](embed:Containers)

### Trust boundaries

Placement is hybrid, and each boundary is crossed under a named identity rather
than from a trusted network position. ADR-0005 moves the lab tier — gateway,
self-hosted model and observability — onto Azure Container Apps in the lab
subscription, with logs and traces in Application Insights and metrics in Azure
Monitor managed Prometheus; the on-prem cluster stays in the model as the
documented exit environment.

| Boundary | What crosses it | Under what identity |
| --- | --- | --- |
| Consumer to platform | Chat, completion and embedding requests | Entra ID bearer token, validated by the gateway against JWKS |
| Platform to Azure | Entitlement reads, secret reads, hosted model calls | Managed identity; no long-lived credential in the runtime |
| Platform to external providers | Model calls to Anthropic and OpenAI | Provider API key read from the secret store at call time |
| Platform to self-hosted runtime | Model calls for data classes that may not leave own-tenancy infrastructure | Inside the Container Apps environment; no prompt leaves the subscription |
| Operator to admin surfaces | Gateway, policy and dashboard administration | Zero-trust proxy on device posture and phishing-resistant MFA |
| Platform to Microsoft 365 tenant | Copilot estate administration | Dry-run only; the call is printed, not made |

There is no network perimeter to be inside of. An operator on the corporate
network has no more access to an admin surface than one at home; both go through
the proxy.

![Platform deployment view: where each part runs, and which boundaries a call crosses](embed:PlatformDeployment)

### One request, end to end

![Dynamic view: what happens on one chat completion request](embed:ChatCompletion)

### Documented and running are not the same thing

A box on these diagrams says the design exists. It does not say the thing is
deployed. The repository README carries the status legend; this model marks the
distinction in two places:

- A deployment node tagged `documented` is drawn with a dashed border. It is a
  placement option that has been written down and not built. Two examples: the
  APIM AI Gateway, the Azure-native alternative to the self-hosted gateway; and
  the on-prem Kubernetes node, which since ADR-0005 is the exit environment
  rather than the lab tier, and holds manifests rather than running instances.
  The Loki and Tempo containers carry the same tag for the same reason.
- The Copilot estate is administered, not built. Its automation runs against
  Microsoft Graph in dry-run mode: there is no tenant to change, and the output
  of a run is the call it would have made.

Read a dashed node, and anything in the Copilot layer, as a design that has been
exercised — not as a control that is in force.
