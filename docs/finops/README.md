# FinOps

- **Owner** — FinOps
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — provider contracts and commitments (`docs/vendors/`); the telemetry
  pipeline the numbers come from (`telemetry/`); and the firm's general cost management,
  which this feeds rather than replaces.

Cost allocation, showback and budget guardrails: the attribution model that turns gateway
metadata into a cost per consumer, the showback reporting cadence, budgets and their
enforcement at the gateway, unit economics per workload, and the thresholds that trigger a
conversation rather than a block.

Budgets are a control, not a report. A consumer over budget is throttled or stopped by the
gateway, and the rule that does it is defined here and implemented in `gateway/`.

Arrives in **Phase 2**, once telemetry has produced enough data to allocate against.
