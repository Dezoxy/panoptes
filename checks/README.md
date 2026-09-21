# Checks

- **Owner** — AI Platform
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — the generic hooks in `.pre-commit-config.yaml`; application tests in
  `tests/`; and runtime policy enforcement, which happens in the gateway, not in CI.

Repository-specific quality gates, run in pre-commit and again in CI. Three are intended:

- **ADR linter** — every file in `adr/` has the required sections in order, a valid status
  as the first word under `## Status`, a number matching its filename, and a non-empty
  `Rejected alternatives` section. It makes the rule in `adr/README.md` enforceable.
- **Docs-to-IaC drift check** — placements documented in `docs/architecture/` and `adr/`
  match what Terraform in `iac/` actually creates. Documentation that disagrees with the
  estate is worse than none.
- **Cost anomaly detection** — spend per consumer against the budgets in `docs/finops/`,
  flagging step changes rather than absolute thresholds.

Arrives in **Phase 4**, once the repository holds enough for the checks to check.
