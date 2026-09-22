# Runbooks

- **Owner** — Service Management
- **Status** — Draft
- **Last reviewed** — 2026-09-22
- **Out of scope** — service level objectives and error budgets (`slos/`); architecture and
  design rationale (`docs/architecture/`, `adr/`); and consumer workload operations, which
  their owners run.

On-call procedures and incident response: one runbook per alert that can page, plus
procedures for the recurring operational work — provider outage and failover, quota and
budget exhaustion, credential rotation, capacity changes, and the platform's own
escalation path.

A runbook is written for someone woken at 03:00 who did not build the thing. If it needs
context to follow, it is a design document with the wrong filename.

Accumulates from **Phase 1**. The rule is simple: an alert without a runbook does not get
to page.

## Runbooks

- [Rotating a gateway secret](gateway-secret-rotation.md) — a new revision, not a restart.
