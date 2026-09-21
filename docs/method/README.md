# Method

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-21
- **Out of scope** — the architecture itself, which lives in `docs/architecture/`; the
  decisions it produced, which live in `adr/`; the consumer-facing lifecycle material in
  `docs/onboarding/`. This directory says how the platform is designed, decided and
  written down, not what was decided.

Six documents. If you are only editing prose, `documentation-conventions.md` is enough. If
you are proposing a change to the platform, read `rfc-and-review.md` first — it tells you
whether you owe an RFC, an ADR, or neither.

## Index

- [`adr-template.md`](adr-template.md) — the architecture decision record template, with
  the filename, numbering and status rules the importer and the ADR linter both depend on.
  Copy the template body into `adr/NNNN-kebab-title.md` and delete the guidance comments.
- [`c4-conventions.md`](c4-conventions.md) — how the system is modelled: Structurizr DSL,
  which of the seven Panoptes layers become containers and which become groups, and how
  trust boundaries are expressed. It also states the three views every system must carry
  and why hand-drawn images are not accepted.
- [`risk-tiering.md`](risk-tiering.md) — the rubric a consumer workload is scored against
  at intake, on four axes, producing tier 1, 2 or 3. The tier then fixes the review gate,
  the providers the workload may reach, its logging mode, its pilot, and who signs it off.
- [`rfc-and-review.md`](rfc-and-review.md) — when a change needs an RFC, when it needs an
  ADR, and when a plain pull request is the right size. It also defines the review window,
  the reviewers per area, and what "accepted" means.
- [`documentation-conventions.md`](documentation-conventions.md) — the header block every
  document in this repository carries, what each field means, and the staleness rule. It
  also fixes spelling, file naming and the diagrams-as-code rule.

## Precedence

The method documents expand on the working agreement in `CONTRIBUTING.md`; they do not
override it. Where the two disagree and the disagreement is not recorded, `CONTRIBUTING.md`
wins and the method document is the one to fix. Where a divergence is recorded — as the
status vocabulary is, in `documentation-conventions.md` — it is a known reconciliation
still owed, not licence to ignore either document.
