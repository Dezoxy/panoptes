# 0006. Raise dependency updates with Renovate instead of Dependabot

## Status

Accepted

## Date

2026-09-22

## Context

Version updates were raised by Dependabot from `.github/dependabot.yml`, one entry per
ecosystem: GitHub Actions, Terraform, uv and the gateway `Dockerfile`. On its first run it
opened five pull requests within a minute of each other (#12 to #16), one per dependency and
none grouped. One of them, #16, proposed `hashicorp/azurerm` 4.81 to 5.6, a major provider
release that changes resource schemas; it arrived in the same batch and the same form as the
routine action bumps, and was closed unmerged.

Dependabot also cannot see several pins that decide what runs. It has no way to read a
version from an arbitrary file, so it misses the OpenTelemetry collector image held as a
string default in `../iac/azure/variables.tf` (that image runs as the gateway's sidecar in
the lab tier, ADR-0005) and version strings in YAML that is not a recognised manifest, such
as the Structurizr CLI tag in `../.github/workflows/architecture.yml`. The pins it cannot see
are exactly the ones nobody is reminded to move.

The owner's other estate already runs Renovate with one pull request open at a time, a fixed
weekly window in Europe/Budapest and regex managers for pins held in variables. Running a
second tool with a second configuration dialect here buys nothing.

This needs a record rather than a configuration commit because the tool is a third-party
GitHub App with write access to the repository. That places a security boundary with a
vendor, which is one of the thresholds in `../CONTRIBUTING.md`.

## Decision drivers

- **Every pin that decides what runs is covered.** Container images in Terraform variables,
  Compose and the `Dockerfile`; Terraform providers; action references; pre-commit hook
  revisions; Python dependencies and `uv.lock`.
- **Review load fits one operator.** Updates arrive on a known day, one pull request at a time,
  with a single place that lists what is waiting.
- **A provider major is not routine.** A major `azurerm`, `azuread`, `azapi` or `random` release
  can change resource schemas; it needs a `terraform plan` read by a person before it is even
  raised.
- **No new credential stored in the repository or its settings** (ADR-0004 driver: no stored
  credentials).
- **Consistency with the owner's other estate.** A preference, not a requirement; labelled as
  one.

## Considered options

1. Renovate, through the Mend-hosted GitHub App, configured by `renovate.json` in the
   repository.
2. Keep Dependabot version updates.
3. Run Renovate and Dependabot version updates side by side.
4. Self-hosted Renovate, run as a scheduled GitHub Actions workflow.
5. Manual updates, with no bot.

## Decision

Dependency updates are raised by **Renovate through the Mend-hosted GitHub App**, installed on
`Dezoxy/panoptes` only, with its configuration in `../renovate.json`. Renovate runs weekly,
before 07:00 on Monday in Europe/Budapest, keeps at most one of its pull requests open at a
time, and maintains a dependency dashboard issue that lists everything pending. Actions are
pinned to commit digests, and non-major action updates are grouped into one pull request. A
regex manager reads container image pins from `default` values in
`../iac/azure/variables.tf`; the `panoptes-gateway` image there is excluded, because that pin
is this repository's own release and is moved by hand. Terraform provider major updates are
never raised without approval from the dashboard, and carry a `needs-plan-review` label when
they are. Nothing automerges. Dependabot version updates are removed; Dependabot alerts, a
repository setting rather than part of `dependabot.yml`, remain the vulnerability signal. That
setting was found disabled when this record was written (checked through the GitHub API on
2026-09-22), so enabling it is an operator step alongside installing the app.

## Consequences

### Positive

- The OpenTelemetry collector pin in `../iac/azure/variables.tf` and its twin in
  `../gateway/compose.yaml` are now seen, and move together in one pull request because they
  share a package name.
- A provider major cannot arrive unannounced: it waits on the dashboard until someone ticks it,
  and the label says what the reviewer owes before merging.
- Action references are pinned to digests, so a moved tag upstream no longer changes what CI
  runs without a pull request.
- One tool and one configuration dialect across the owner's estate.

### Negative and accepted trade-offs

- **A third-party app holds write access to the repository.** The Mend app asks for write on
  contents, pull requests, issues, workflows, checks and statuses (its published permission
  set, read through the GitHub API on 2026-09-22), and clones the repository on the vendor's
  infrastructure. A regulated firm would put that through vendor due diligence before
  installing it: data handling, hosting location, sub-processors, incident notification, and
  the ability to revoke. For this lab, on a public repository that holds no secrets, the risk
  is accepted without that review. It is recorded here so the gap is visible, not closed.
- **"Nothing automerges" is configuration, not enforcement.** The `protect-main` ruleset
  requires a pull request but zero approvals and no status checks, so an app with write access
  could merge its own pull request if its configuration or its vendor were compromised.
  Direct pushes to `main` are blocked by that ruleset, and the Azure federated credential
  trusts only `refs/heads/main`, so a Renovate branch alone cannot reach Azure.
- **Renovate moves the pin, not the prose.** `../gateway/Dockerfile` and
  `../gateway/otel/collector.yaml` carry comments recording that a tag was verified present on
  a date. The reviewer of a Renovate pull request updates those comments in the same branch or
  the comment becomes false.
- **One pull request at a time can queue.** An unreviewed Renovate pull request holds back
  every routine update behind it; the dashboard shows the queue. Vulnerability fixes are not
  held: Renovate's `vulnerabilityAlerts` defaults give them no schedule and no concurrency
  limit (read from the Renovate 44.107.3 source on 2026-09-22). They depend on Dependabot
  alerts being enabled, which is the operator step named in the Decision.
- **The first run is noisy by design.** Pinning actions to digests produces one pull request
  touching every workflow before regular updates start.
- **The Structurizr CLI tag is still unmanaged.** It is quoted in both
  `../.github/workflows/architecture.yml` and `../docs/architecture/README.md`, and a regex
  manager for it is a later change, not this one.

## Rejected alternatives

### Option 2 — Keep Dependabot version updates

- **Why not** — no regex or custom managers, so pins held in Terraform variables and in
  non-manifest YAML stay invisible; no grouping across ecosystems, so related bumps arrive as
  separate pull requests; no dashboard, so there is no single list of what is pending or held.
  The five pull requests of its first run are the evidence.
- **Revisit if** — Dependabot gains user-defined version extraction and a pending-updates view,
  or a vendor review rejects the Mend app and self-hosting (option 4) is also ruled out.

### Option 3 — Run Renovate and Dependabot version updates side by side

- **Why not** — both tools would raise the same action, provider and image bumps, so every
  update would arrive twice and one of each pair would have to be closed by hand.
- **Revisit if** — never as a standing arrangement. At most a single transition week, which this
  change does not need because `dependabot.yml` is removed in the same pull request.

### Option 4 — Self-hosted Renovate on GitHub Actions

- **Why not** — to open pull requests that trigger CI, a self-hosted run needs its own GitHub
  App, and that app's private key has to be stored as a repository secret. That is a long-lived
  credential with write access, which is what ADR-0004 set out to avoid. It also adds a
  workflow to keep working.
- **Revisit if** — the hosted app fails vendor review, the firm will not permit a third party to
  hold write access, or the repository moves somewhere the hosted app cannot reach.

### Option 5 — Manual updates

- **Why not** — depends on one person remembering to look, across six ecosystems, with no
  signal when they forget. Pins go stale quietly.
- **Revisit if** — the repository is frozen or archived and only security fixes matter.

## Risks

- **The vendor or its app is compromised.** Detectable through the repository audit log and
  through pull requests or branches the operator did not expect from `renovate[bot]`. The
  response is to suspend the installation from the owner's GitHub settings.
- **Renovate stops running without anyone noticing.** Detectable when the dependency dashboard
  issue stops updating on Mondays, or when the Mend job log for the repository shows errors.
- **A provider major is approved without a plan being read.** Detectable in review: a
  `needs-plan-review` pull request merged without a plan output in its conversation.
- **Vulnerabilities go unseen.** Detectable today: Dependabot alerts are off until the operator
  enables them, and Renovate's vulnerability pull requests depend on reading those alerts.
- **Hook revisions are bumped twice.** The `ci:` block in `../.pre-commit-config.yaml` configures
  pre-commit.ci autoupdates. No pre-commit.ci pull request has been seen on the repository; if
  that app is ever installed, its autoupdate overlaps with Renovate's pre-commit manager and one
  of them has to be turned off.

## Related

- **Requirements** — `../CONTRIBUTING.md`, `../renovate.json`, `../.pre-commit-config.yaml`
- **Other ADRs** — [0004](0004-ci-on-github-actions.md), [0005](0005-lab-tier-on-azure.md)
