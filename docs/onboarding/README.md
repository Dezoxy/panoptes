# Onboarding

- **Owner** — AI Platform
- **Status** — Planned
- **Last reviewed** — 2026-09-22
- **Out of scope** — the risk rubric itself, which is in `docs/method/risk-tiering.md`; the
  CLI that drives intake, which is in `automation/`; and platform-internal change review,
  which is in `docs/method/rfc-and-review.md`.

The consumer workload lifecycle, from discovery through to retirement: the intake
questionnaire, the four stages and what it takes to leave each one, the review gates per
risk tier, the evidence a workload must produce before production, re-review cadences, and
the retirement checklist — including credential revocation and what happens to the data.

The same four stages — Discovery, Pilot, Production, Retiring — apply to platform services
and to consumer workloads, so both are described in the same terms.

[`platform-responsibility-matrix.md`](platform-responsibility-matrix.md) is the document a
team reads before intake. It sets out, per layer of an agentic workload, who owns it, what
the platform provides, what the consuming team decides, and which tools are Supported,
Tolerated or Forbidden.

Arrives in **Phase 3**, with the policy engine and the CLI that enforce it. Phase 3 also
delivers the golden-path workload template, scaffolded by `panoptes onboard scaffold`, so a
team starts on the paved road rather than wiring the gateway client and telemetry by hand.
