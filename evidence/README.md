# Evidence

- **Owner** — AI Platform / Security
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — the policies the evidence demonstrates (`policies/`); the collectors
  that produce it (`automation/`, `telemetry/`); and audit response, which is the firm's
  second line, not the platform's.

Control evidence collected for audit: policy decision extracts, entitlement and access
reviews, approval records with their DPIA references, provider configuration snapshots,
and the onboarding artefacts each workload produced before production.

**Files here are produced by automation and are not authored by hand.** If a control
cannot be evidenced by a job that runs on a schedule, it is not yet a control. This
`README.md` is the only file in the directory a person writes. The directory is excluded
from pre-commit formatting, markdownlint and yamllint: collected output is not
reformatted, because reformatting breaks the chain back to what was observed.

Accumulates from **Phase 1**, as soon as the gateway is producing policy decisions.
