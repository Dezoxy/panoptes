# Telemetry

- **Owner** — AI Platform
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — the cost model and showback policy built on this data
  (`docs/finops/`), the service level objectives measured from it (`slos/`), and
  application logging inside consumer workloads, which their owners run.

Collectors, pipelines, dashboards and alert definitions for `panoptes-meter`:
OpenTelemetry configuration, the metric and attribute schema every gateway call emits,
retention rules per signal, and the dashboards and alerts built on top.

The default is metadata only — who called, when, which model, tokens, latency, policy
decision, cost. Prompt and completion bodies are not collected unless a workload has an
approval and a DPIA reference recorded against it, per `docs/method/risk-tiering.md`.

Arrives in **Phase 1**, alongside the gateway. A gateway with no meter is not operable.
