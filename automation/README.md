# Automation

- **Owner** — AI Platform
- **Status** — Planned
- **Last reviewed** — 2026-09-22
- **Out of scope** — CI workflow definitions, which live in `.github/`; the repository
  quality gates, which live in `checks/`; and the Python package itself, which lives in
  `src/`. This directory holds operational tooling and the jobs that run it.

Operational tooling and scheduled jobs: the `panoptes` CLI surfaces (`onboard`, `budget`,
`evidence`, `copilot`), the Copilot estate administration scripts, and the scheduled jobs
that collect evidence, reconcile budgets and reconcile documented placements against what
is actually deployed.

What the CLI will provide, beyond the four surfaces above:

- `panoptes onboard scaffold <name>` — writes a workload template: the gateway client
  configured from the intake record, OpenTelemetry wired to the platform collector, a
  promptfoo evaluation suite skeleton, policy hooks and tests. A team starts on the paved
  road rather than assembling it. **Phase 3**.

Anything touching Microsoft Graph runs in dry-run mode only. There is no tenant behind it,
and the output of a dry run is the call that would have been made — not a simulated result.

Arrives in two steps: the **Phase 2** Copilot estate scripts, then the **Phase 3** CLI.
