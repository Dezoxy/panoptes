# Panoptes (Greek: all-seeing) — the shared AI platform for Northgate Asset Management

- **Owner** — AI Platform
- **Status** — Draft
- **Last reviewed** — 2026-09-22
- **Out of scope** — model training and fine-tuning; data science tooling; end-user
  application development; Microsoft 365 tenant operation outside the Copilot surfaces
  listed in the catalogue.

Panoptes is a shared AI platform that Tom Horvath builds and operates himself. It runs on
his own Kubernetes and Azure estate and talks to live model providers. Northgate Asset
Management is a fictional tenant: the name exists so that entitlements, data classes and
rollout plans can be written for a regulated asset manager instead of for a sandbox.
Panoptes is not deployed at any company.

## Scope

The platform provides:

- A model gateway with routing, fallback, quotas and audit.
- A controls plane: identity, entitlements, policy as code, evidence collection.
- Telemetry and cost attribution, with budgets per consumer.
- A risk-based onboarding lifecycle, from discovery through to retirement.
- Copilot estate administration.
- Technical ownership of model and assistant vendors.

## Architecture in one paragraph

Seven layers: consumers call the **model gateway**, which fronts the **providers**; the
**controls plane** decides what each consumer may do; **telemetry and FinOps** records what
it did and what it cost; the **lifecycle** governs how a workload gets in and out; the
**Copilot estate** is the part of the fleet administered rather than built. Placement is
hybrid. An Azure subscription hosts the control plane and the hosted models. External
providers (Anthropic, OpenAI) are reached only through the gateway — never directly by a
consumer. The lab tier — gateway, self-hosted model and observability — runs on Azure
Container Apps in the lab subscription, scaling to zero, with logs and traces in
Application Insights and metrics in Azure Monitor managed Prometheus (ADR-0005); the
on-prem Kubernetes cluster is the documented exit environment rather than a running tier.
Admin-plane access goes through a zero-trust proxy rather than a network perimeter. The C4
model is in `docs/architecture/` and placement decisions in `adr/`.

## Service catalogue

Nothing in this table runs yet. Every row is at its starting state; the table is the plan
of record, not a description of a running system.

| Service | Component | Build status | Lifecycle stage | Owner |
| --- | --- | --- | --- | --- |
| Model gateway | `panoptes-gateway` | Planned | Discovery | AI Platform |
| Telemetry and cost | `panoptes-meter` | Planned | Discovery | AI Platform |
| Policy engine and evidence | `panoptes-policies` | Planned | Discovery | AI Platform / Security |
| Platform CLI | `panoptes` (`onboard`, `budget`, `evidence`, `copilot`) | Planned | Discovery | AI Platform |
| Provider integrations | Azure AI Foundry, Anthropic, OpenAI, self-hosted | Planned | Discovery | AI Platform |
| Observability | dashboards and alerting | Planned | Discovery | AI Platform |
| Onboarding lifecycle | templates and review gates | Planned | Discovery | AI Platform |
| Copilot estate | M365 Copilot, GitHub Copilot, Copilot Studio administration | Planned | Discovery | AI Platform |
| Vendor management | due diligence, renewals, exit plans | Planned | Discovery | AI Platform / FinOps |
| Self-service portal | request and status surface for consumers | Planned | Discovery | AI Platform |
| Developer documentation site | `docs.panoptes.northgate.internal` | Planned | Discovery | AI Platform |

Copilot estate is expected to reach **Dry-run** once its automation is written. It is
**Planned** today.

## Status legend

Build status — what exists:

- **Running** — deployed, monitored, in the on-call rota.
- **Documented** — design and runbooks complete; not deployed.
- **Dry-run** — automation exists and is exercised with `--dry-run`; there is no tenant to
  run it against.
- **Planned** — not built.

Lifecycle stage — where a service sits in its own life: **Discovery**, **Pilot**,
**Production**, **Retiring**.

These are the same four stages the onboarding lifecycle applies to consumer workloads, so a
platform service and a workload using it are described in the same terms.

## What runs and what is documented

This is the target split. Today nothing runs; the catalogue above is the current state.

| Runs on the estate | Documented and dry-run only |
| --- | --- |
| Gateway with three providers, quotas and fallback, on Azure Container Apps | Microsoft 365 Copilot tenant administration |
| Cost dashboards, on Azure-native logs, traces and metrics | GitHub Copilot tenant administration |
| Policy checks in CI | Third-party risk and procurement flow |
| Onboarding CLI | On-prem Kubernetes as the exit environment: Compose file and manifests, never applied |

No tenant is simulated. Where a control needs a Microsoft 365 tenant, the tenant is absent,
not faked: scripts that touch Microsoft Graph run in dry-run mode only, and their output is
the call they would have made. Read the right-hand column as a design that has been written
down and exercised, not as a control that is in force anywhere.

## Repository layout

```text
README.md            # this file
docs/method/         # how the platform is designed, reviewed and documented; templates
docs/architecture/   # C4 model in Structurizr DSL
docs/onboarding/     # lifecycle stages, risk tiers, review gates
docs/copilot/        # Copilot estate administration and rollout guidance
docs/finops/         # cost allocation, showback, budget guardrails
docs/vendors/        # due diligence, contracts, renewals, exit plans
adr/                 # architecture decision records
gateway/             # gateway configuration, routing rules, quotas
iac/                 # Terraform for the Azure landing zone and cluster platform
policies/            # policy as code: admission and usage rules
telemetry/           # collectors, pipelines, dashboards, alert definitions
automation/          # operational tooling and scheduled jobs
portal/              # self-service portal
docs-site/           # developer documentation site sources
runbooks/            # on-call procedures and incident response
slos/                # service level objectives and error budgets
evidence/            # control evidence collected for audit (not authored by hand)
checks/              # ADR linter, docs-to-IaC drift check, cost anomaly detection
CHANGELOG.md         # notable changes
CODEOWNERS           # review requirements per path
SECURITY.md          # vulnerability reporting, scope, secret handling
CONTRIBUTING.md      # working agreement
```

Directories are added as their phase lands. A missing directory means unbuilt, not lost.

## Working in this repository

- Read `CONTRIBUTING.md` first. It sets conventional commits with a fixed type and scope
  list, and it expects `pre-commit install --hook-type pre-commit --hook-type commit-msg`
  before your first commit.
- An ADR without rejected alternatives is not accepted. Record what was turned down and
  what would have to change for the decision to be revisited.
- Every document in this repository carries the same header block: Owner, Status, Last
  reviewed, Out of scope. A document nobody has reviewed in a year is stale by definition.

## Naming

- Kubernetes namespace: `panoptes`
- Python package: `panoptes_platform`
- CLI: `panoptes`
- Components: `panoptes-gateway`, `panoptes-meter`, `panoptes-policies`

The repository lives at `github.com/Dezoxy/panoptes`. There is no GitHub organisation
behind it; ownership is one person, as `CODEOWNERS` records.
