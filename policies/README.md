# Policies

- **Owner** — AI Platform / Security
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — firm-level information security policy, which this implements rather
  than defines; the risk rubric that decides which policy set applies
  (`docs/method/risk-tiering.md`); and the evidence that policies were enforced
  (`evidence/`).

Policy as code: admission and usage rules evaluated by `panoptes-policies`. Entitlements
per consumer, allowed model and provider sets, the data classification matrix that says
which provider may see which data class, content and retention rules, and the Terraform
and Kubernetes admission policies that keep the estate matching what was decided.

A policy here is executable. If a control cannot be expressed as a rule that runs, it is
process and belongs in `docs/onboarding/` or a runbook, where it is honest about being
manual.

Arrives in **Phase 3**, once there is enough running to enforce against.
