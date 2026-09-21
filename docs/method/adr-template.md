# ADR template

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-21
- **Out of scope** — which decisions need an ADR at all; that threshold is set in
  `CONTRIBUTING.md` and expanded in [`rfc-and-review.md`](rfc-and-review.md). This document
  only fixes the shape of the record once you have decided to write one.

## How to use it

Copy the template body below into `adr/NNNN-kebab-title.md`, fill it in, and delete every
guidance comment. The ADR lands in the same pull request as the change it authorises, or
before it — never after.

## Filename and numbering

- Path: `adr/NNNN-kebab-title.md`. One file per decision, no subdirectories.
- `NNNN` is four digits, zero-padded, starting at `0001`. The number is read from the first
  four characters of the filename; nothing else carries it. Do not repeat it in the body
  beyond the title line.
- The title is a short imperative phrase in kebab-case: `0004-route-mnpi-workloads-to-azure-only.md`.
- Numbers are allocated on merge, not on branch. If two ADRs collide, the second to merge
  renumbers — the number is an identifier, not a claim of priority.
- Never renumber or delete a merged ADR. A decision that no longer holds gets a new ADR and
  a status change on the old one.

## Status lifecycle

Exactly one of:

| Status | Meaning |
| --- | --- |
| `Proposed` | Written, open for review, not yet binding. |
| `Accepted` | Binding. The platform is expected to match it. |
| `Superseded by NNNN` | A later decision replaced it. The record stays for the history. |
| `Deprecated` | No longer binding and not replaced — the context it addressed is gone. |

The status is the **first word of the first non-empty line under `## Status`**. That is an
importer convention inherited from adr-tools and the ADR linter in `checks/` enforces it.
Anything else in that section — links to other ADRs — goes on later lines, still inside
`## Status`, before `## Context`.

`Superseded by 0012` is followed on the next line by the link, so the first word remains
`Superseded`.

## Required sections

All nine headings below are required and must appear in this order. **Rejected
alternatives** is the section this repository will not accept an ADR without: an ADR that
lists options and picks one, but never says why the others were turned down or what would
bring them back, is a note, not a decision record.

## Template body

```markdown
# NNNN. Short imperative title of the decision

## Status

Proposed

<!--
First word of the first non-empty line above is the status the importer and the ADR
linter read: Proposed | Accepted | Superseded by NNNN | Deprecated.

Links to other ADRs sit here, inside Status, before ## Context. Paths are relative to
adr/, so they look like this:

Superseded by 0012
[0012. Move hosted models to a dedicated subscription](0012-move-hosted-models-to-a-dedicated-subscription.md)

Supersedes [0003. Route all traffic through a single provider](0003-route-all-traffic-through-a-single-provider.md)

Delete this comment.
-->

## Date

2026-09-21

<!-- ISO date the status above was reached, not the date drafting started. -->

## Context

<!--
What is the problem, and what forces make it a problem now? Business, regulatory,
technical, operational, cost. Name the consumer workload or platform capability that
forced the question. If a constraint is imposed rather than chosen — a tenant boundary, a
contract, a regulator's expectation — say so, and say by whom.
-->

## Decision drivers

<!--
The criteria the options were judged against, most important first. Link each driver to
the thing it comes from where one exists: a risk tier in
../docs/method/risk-tiering.md, a control in ../policies/, an SLO in ../slos/. A driver
nobody can trace to a requirement is a preference; label it as one.
-->

- ...

## Considered options

<!-- Every option that was genuinely on the table, including "do nothing". -->

1. ...
2. ...
3. ...

## Decision

<!--
One paragraph, present tense, active voice: "The gateway routes ... ". State what is now
true, not what someone intends to do later. Scope it: which consumers, which data
classes, which environments.
-->

## Consequences

### Positive

- ...

### Negative and accepted trade-offs

<!--
What this costs. Be specific: latency, spend, operational load, lock-in, a control that
now has to be carried by process rather than by the platform. "None" is almost never
true; if you cannot name one, the decision was probably not a decision.
-->

- ...

## Rejected alternatives

<!--
REQUIRED. One entry per option from Considered options that was not chosen. Each entry
needs both halves: why it lost, and the condition that would make it worth reopening.
"Too expensive" is not a reason; "roughly 3x the run rate at the volumes in
../docs/finops/, and the difference buys a control we already get elsewhere" is.

An ADR without this section is not accepted. This is enforced by CODEOWNERS review and
by the ADR linter in ../checks/.
-->

### Option N — title

- **Why not** — ...
- **Revisit if** — ...

## Risks

<!--
What could make this decision wrong, and how we would find out. Prefer a detectable
signal over a worry: name the metric, alert, review or audit finding that would surface
it. Link to the risk register once one exists.
-->

- ...

## Related

<!-- Delete the lines that have nothing to point at. Keep the headings you use. -->

- **Requirements** —
- **Architecture views** —
- **Other ADRs** —
```

## Where reasons were never recorded

If you are writing an ADR after the fact for a decision whose reasoning nobody wrote down,
say exactly that in `## Context` and leave `## Rejected alternatives` naming the options
with `Why not — not recorded`. Do not reconstruct a plausible reason. An honest gap is
auditable; an invented rationale is not.
