# Infrastructure as code

- **Owner** — AI Platform / Security
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — application configuration, which lives with each component; the
  Microsoft 365 tenant, which is administered rather than provisioned (`docs/copilot/`);
  and consumer workloads, which bring their own infrastructure.

Terraform for the Azure landing zone and the on-prem Kubernetes cluster platform:
subscription and resource group layout, networking, identity and role assignments, Key
Vault, the hosted model deployments, and the cluster add-ons the platform depends on.

State is remote and never committed. `*.tfvars` are gitignored; documented input samples
are tracked as `*.auto.tfvars.example`. The `terraform_fmt`, `terraform_validate`,
`tflint`, `trivy` and `checkov` hooks all run on this path.

Spans **Phase 1** — the landing zone and cluster platform the gateway needs — and
**Phase 3**, when policy enforcement and onboarding automation add resources of their own.
