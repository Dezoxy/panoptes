# Infrastructure as code

- **Owner** — AI Platform / Security
- **Status** — Draft
- **Last reviewed** — 2026-09-22
- **Out of scope** — application configuration, which lives with each component; the
  Microsoft 365 tenant, which is administered rather than provisioned (`docs/copilot/`);
  and consumer workloads, which bring their own infrastructure.

Terraform for the Azure landing zone and the on-prem Kubernetes cluster platform:
subscription and resource group layout, networking, identity and role assignments, Key
Vault, the hosted model deployments, and the cluster add-ons the platform depends on.

Phase 1 has started: the Azure root module in [`azure/`](azure/README.md) manages the
lab resource group, the subscription budget and the tag policy assignment; Key Vault,
the Container Apps environment and the gateway workload follow. The on-prem Kubernetes
manifests referenced above stay **Documented**, per
[ADR-0005](../adr/0005-lab-tier-on-azure.md) — the lab tier runs on Azure Container
Apps, and the on-prem cluster is the exit environment these manifests describe rather
than something currently running.

State is remote and never committed. `*.tfvars` are gitignored; documented input samples
are tracked as `*.auto.tfvars.example`. The `terraform_fmt`, `terraform_validate`,
`tflint`, `trivy` and `checkov` hooks all run on this path.

Spans **Phase 1** — the landing zone and cluster platform the gateway needs — and
**Phase 3**, when policy enforcement and onboarding automation add resources of their own.
