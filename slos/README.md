# Service level objectives

- **Owner** — AI Platform / Service Management
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — the telemetry that measures them (`telemetry/`); the procedures for
  when they are breached (`runbooks/`); and provider SLAs, which are contractual terms
  recorded in `docs/vendors/`.

Service level objectives and error budgets for the platform's own services: availability
and latency targets for the gateway, freshness targets for metering and cost data,
onboarding turnaround per risk tier, and the error budget policy — what the platform stops
doing when a budget is spent.

Each objective names its indicator, its measurement window, and the alert derived from it.
An objective nothing measures is an aspiration, and belongs in a roadmap instead.

Accumulates from **Phase 1**, starting with the gateway. Objectives are added as services
reach Production, not before.
