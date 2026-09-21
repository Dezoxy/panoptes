# RFCs and review

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-21
- **Out of scope** — the branch, commit and pull-request mechanics, which are in
  `CONTRIBUTING.md`; the shape of an ADR once you are writing one, which is in
  [`adr-template.md`](adr-template.md); the consumer-workload intake review, which is a
  different process driven by [`risk-tiering.md`](risk-tiering.md) and belongs to
  `docs/onboarding/`. This document is about changes to the platform, not about workloads
  using it.

## Which one do you owe

Three instruments, in descending cost. Pick the cheapest one that fits.

| Instrument | Use it when |
| --- | --- |
| **RFC** | A new platform capability. A change to an already-accepted ADR. A new provider. Anything where the right answer is not yet known and the argument is the work. |
| **ADR** | A decision. The answer is known or the RFC produced it, and what needs recording is the choice, the alternatives and the trade-off. |
| **Plain pull request** | Everything else. Implementation inside a boundary that is already decided. |

The three overlap in one direction only: an RFC ends in an ADR, and an ADR is carried by a
pull request. You never need all three as separate artefacts.

### RFC

Write an RFC when:

- **A new platform capability is proposed.** Something Panoptes does not currently do, that
  consumers would depend on, that the platform would then have to operate.
- **An accepted ADR would change.** Superseding a decision is a decision. It gets the same
  scrutiny the original should have had, plus the question of what it costs to unwind.
- **A new provider is proposed.** A provider is a trust boundary, a contract, a data-flow
  and a bill. Adding one is never only a configuration change.

### ADR

Write an ADR, without an RFC first, when the decision threshold in `CONTRIBUTING.md` is met
but the answer is not in doubt — where something runs, which provider it uses, where a
security boundary sits, how data is handled. If you find yourself writing the RFC's
argument inside the ADR's Context section, you needed an RFC.

### Plain pull request

Everything that stays inside an already-decided boundary: routing rules under an existing
placement, a new dashboard, a runbook, a dependency bump, a fix. If you are unsure whether
a change crosses a boundary, open the ADR — `CONTRIBUTING.md` is right that a rejected ADR
is cheaper than an undocumented boundary.

## RFC lifecycle

An RFC is a pull request labelled `rfc`. It carries the proposal as prose plus the ADR it
would produce, in `Proposed` status. There is no separate RFC directory: a proposal that
cannot be written as a decision record is not yet a proposal.

1. **Draft.** Opened as a draft pull request. No review window is running. Iterate freely.
2. **Review.** Marked ready for review. The window is **five working days** from that
   moment. Reviewers for the affected areas are requested explicitly, not assumed from
   CODEOWNERS alone.
3. **Decision.** At the end of the window the RFC either merges — with the ADR moved from
   `Proposed` to `Accepted` and dated — or it is closed.

Substantive changes during the window restart it. Typos and clarifications do not. The
author decides which a change was, and reviewers may disagree publicly.

Silence at the end of the window is not acceptance. An RFC that reaches day five with no
reader is either extended or accepted explicitly, and an explicit acceptance with no reader
is recorded as such — see below.

A closed RFC stays closed and readable. The argument is the value; it survives the
rejection, and the next person to propose the same thing should find it.

## Reviewers by area

Reviewers mirror the ownership functions in `CODEOWNERS`:

| Area | Reviewing function |
| --- | --- |
| `gateway/`, `telemetry/`, `automation/` | AI Platform |
| `iac/`, `policies/`, `evidence/` | Security |
| `docs/copilot/` | AI Platform |
| `docs/finops/`, `docs/vendors/` | FinOps |
| `runbooks/` | Service Management |
| `docs/method/`, `adr/`, `docs/architecture/`, everything else | AI Platform |

Three additions that apply regardless of which files the change touches:

- A new provider requires **Security** — data flow and trust boundary — and **FinOps** —
  contract, commitment, exit.
- A change to how data is classified, retained or logged requires **Security**.
- A change that would move a workload between risk tiers requires the reviewers that tier
  demands in [`risk-tiering.md`](risk-tiering.md).

Panoptes is maintained by one person, so every function above is currently the same
reviewer. The split is recorded, not enforced: it says which hat is being worn, which is
the part that is easy to lose and expensive to reconstruct later.

## What "accepted" means

Accepted is binding. The platform is expected to match an accepted ADR, and a divergence
from one is a defect in the platform or a signal that the ADR needs superseding — never a
tolerated exception. An accepted ADR is not a recommendation, a preference or a
direction of travel.

Accepted is not permanent. Every ADR carries the condition under which each rejected
alternative would be revisited; when one of those conditions fires, open the RFC.

## Who can accept

The owning function for the area accepts. Where a change spans areas, every affected owning
function accepts, and one dissent blocks — there is no majority.

The author may accept their own RFC, because there is one maintainer and the alternative is
a process that pretends otherwise. The cost of that is visibility: an RFC merged with no
second reader records `Reviewers: none` in the merge commit, so the gap sits in the history
rather than being implied by it. An RFC that touches Security or a new provider should not
be self-accepted without at least recording what the author checked, in the ADR's Risks
section.
