# 0001. Record architecture decisions as ADRs in this repository

## Status

Accepted

## Date

2026-09-21

## Context

Panoptes is designed, built and operated by one person for one tenant. Northgate Asset Management is
fictional, but the constraints written for it are not softened: a regulated asset manager, EU data
residency, MNPI in scope, and an auditor who eventually asks why a control sits where it sits.

The decisions that matter here are placement, provider choice, security boundary and data handling.
Each is cheap to record when it is taken and expensive to reconstruct a year later. A single
operator makes that worse rather than better: no second memory acts as a backup, and no review
meeting catches the argument by accident.

The repository already assumes these records exist. `../CONTRIBUTING.md` sets the threshold that
triggers one, [`../docs/method/adr-template.md`](../docs/method/adr-template.md) fixes the shape,
[`../docs/method/rfc-and-review.md`](../docs/method/rfc-and-review.md) places them in the review
process, and `../checks/` reserves a linter to enforce them. What was missing was the decision
itself. This ADR is that decision, and it is deliberately first: the mechanism has to be binding
before anything is recorded through it.

## Decision drivers

- **Evidence a reviewer can read, not intent.** Tier 3 in
  [`../docs/method/risk-tiering.md`](../docs/method/risk-tiering.md) requires a Security control
  review and a Compliance position on record-keeping before a workload reaches production. Both of
  those read *why* a boundary is where it is, not only *where* it is.
- **The reasoning must outlive the branch and the person.** The model in `../docs/architecture/`
  says what exists; nothing in it says what was rejected.
- **Reviewable in the pull request that makes the change.** A decision that cannot be commented on
  line by line is not reviewed, it is announced.
- **Machine-enforceable.** A convention only a human checks decays. The ADR linter planned in
  `../checks/` needs a fixed location, a fixed section list and a parseable status.
- **Low cost per decision.** A preference, not a requirement — but a process costing an hour per
  decision is the one skipped on the decision that mattered.

## Considered options

1. Numbered ADR files in `adr/`, one decision per file, written to a fixed template.
2. Decisions recorded in wiki pages or issue tickets.
3. Decisions left in code comments and commit messages.
4. One living design document, edited in place as the architecture changes.
5. Do nothing. Decisions stay with whoever made them.

## Decision

Architecture decisions are recorded as ADRs in `adr/`, one decision per file, named
`NNNN-kebab-title.md` and written to the template in
[`../docs/method/adr-template.md`](../docs/method/adr-template.md). A decision crosses the threshold
when it fixes where something runs, which provider it uses, where a security boundary sits, or how
data is handled. Nothing reaches `Accepted` without a populated `Rejected alternatives` section, and
every rejected option carries both halves: why it lost, and the condition that would reopen it. A
change to an `Accepted` ADR goes through the RFC process in
[`../docs/method/rfc-and-review.md`](../docs/method/rfc-and-review.md) rather than through an edit.
An accepted ADR is never edited afterwards except to change its status to `Superseded by NNNN` or
`Deprecated`; the replacing decision is a new, separately numbered record.

## Consequences

### Positive

- The argument survives the merge. Two years on, a reader sees the options that were on the table
  and the condition under which the closed one reopens.
- Decisions are reviewed where the code is, in the same pull request and by the same CODEOWNERS
  entry.
- The record is plain Markdown in the repository: it forks, it diffs, it works offline, and its
  fixed shape lets `../checks/` make the rule enforceable rather than advisory.
- Superseding rather than editing leaves a history of how the platform's thinking changed, which is
  the part a re-review actually needs.

### Negative and accepted trade-offs

- Every placement, provider or security-boundary change now needs a written record before it lands.
  That is real friction on small changes near a boundary, and it is accepted deliberately: the
  alternative is discovering the boundary by incident.
- Changing an accepted decision costs an RFC and a five-working-day review window, even when author
  and reviewer are the same person.
- The record can drift from the estate. An ADR asserts what was decided, not what is deployed; only
  the drift check planned in `../checks/` closes that gap.

## Rejected alternatives

### Option 2 — decisions in wiki pages or issue tickets

- **Why not** — the record lives outside the repository, so it is unversioned against the code it
  describes, it is not reviewable in the pull request that makes the change, and it is lost when the
  tool is replaced or the project is forked. A ticket also records a task, not a decision: it
  closes, and closed tickets are not read.
- **Revisit if** — the firm mandates a system of record for architecture decisions that exports to
  plain text and can be linked from the pull request. Even then, `adr/` stays the source and the
  export is a copy.

### Option 3 — decisions in code comments and commit messages

- **Why not** — a comment explains the line it sits on, never the option turned down. Reasoning
  scatters across files, a decision spanning the gateway, Terraform and policy has nowhere to live,
  and rewriting the code deletes the record.
- **Revisit if** — never as the primary record. Comments remain useful pointers and should reference
  the ADR number where a boundary is implemented.

### Option 4 — a single living design document

- **Why not** — editing in place destroys the history of why, which is the thing worth keeping.
  There is no per-decision status, so a superseded choice and a current one read identically, and a
  long document invites merge conflicts on every concurrent change.
- **Revisit if** — a reader-facing summary is needed; that is a separate document linking to the
  ADRs, not a replacement. `../docs/architecture/overview/README.md` already plays it.

### Option 5 — do nothing

- **Why not** — with one operator, undocumented reasoning is one person away from being gone. A tier
  3 workload cannot pass its Security and Compliance review on a topology diagram alone.
- **Revisit if** — no condition. The platform handles Restricted data classes; unrecorded boundary
  decisions are not acceptable at any team size.

## Risks

- **The record decays into a formality.** Detectable: ADRs whose `Rejected alternatives` entries
  name options nobody weighed, or whose `Revisit if` says "if requirements change". Caught in
  CODEOWNERS review and partly by the linter in `../checks/`.
- **ADRs are written after the implementing pull request merges.** Detectable as a boundary change
  in `../iac/` or `../gateway/` with no ADR reference; the drift check in `../checks/` is the
  intended signal.
- **Superseding is avoided because the RFC costs more than a quiet edit.** Detectable as substantive
  diffs to accepted ADRs in file history.

## Related

- **Requirements** — `../CONTRIBUTING.md`,
  [`../docs/method/rfc-and-review.md`](../docs/method/rfc-and-review.md)
- **Other ADRs** — [0002. Hybrid topology and placement](0002-hybrid-topology-and-placement.md),
  [0003. Model gateway on LiteLLM](0003-model-gateway-litellm.md), [0004. CI/CD on GitHub
  Actions](0004-ci-on-github-actions.md)
