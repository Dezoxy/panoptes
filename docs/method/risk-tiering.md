# Risk tiering

- **Owner** — AI Platform / Security
- **Status** — Active
- **Last reviewed** — 2026-09-21
- **Out of scope** — model evaluation and accuracy testing; the firm's enterprise risk
  taxonomy, which this rubric maps onto but does not replace; vendor risk, which is scored
  separately in `docs/vendors/`; the lifecycle stages themselves, which are in
  `docs/onboarding/`. This document assigns a tier. What the tier then triggers
  operationally is the lifecycle's problem.

Every consumer workload is scored at intake, before it is allowed to call the gateway. The
tier it lands in fixes the review it gets, the providers it may reach, what may be logged,
how long it must pilot, how often it is re-reviewed, and who signs it into service.

## How scoring works

Four axes. Each is scored 1, 2 or 3 against the levels below. **The highest-scoring axis
sets the tier.** Scores are not averaged, weighted or traded off: a single 3 makes the
workload tier 3 regardless of the other three axes.

This is deliberate. The axes describe different ways the same workload can hurt the firm,
and a low score on three of them does not make the fourth safe.

Score the workload as it is intended to run in production, not as the pilot runs it. If a
control is planned but not built, it does not count.

### Axis 1 — Data classification handled

The highest classification the workload sends to a model or retrieves into a prompt,
including data reached through tools and retrieval, not just what the user types.

| Level | Classification |
| --- | --- |
| 1 | Public, or Internal. |
| 2 | Confidential, including client personal data. |
| 3 | Restricted, including material non-public information (MNPI). |

### Axis 2 — Autonomy

How much of the loop the model closes without a person in it.

| Level | Autonomy |
| --- | --- |
| 1 | Assistive. A human reads the output and decides what to do with it. |
| 2 | A human approves each action before it takes effect. |
| 3 | Autonomous action on systems of record. Nobody approves individual actions. |

Batch approval of a queue is level 3, not level 2. "Each action" means each action.

### Axis 3 — Audience

Who can see the output, and where it can end up.

| Level | Audience |
| --- | --- |
| 1 | Internal users only. Output stays inside the firm. |
| 2 | Internal, but the output leaves the firm — for example client reports drafted by the workload and sent on by a person. |
| 3 | Client-facing or public-facing. The output reaches someone outside the firm without a person rewriting it. |

### Axis 4 — Decision impact

What the output is used to decide.

| Level | Impact |
| --- | --- |
| 1 | Informational. Nothing is decided on it. |
| 2 | Operational. Internal process, workflow or prioritisation decisions. |
| 3 | Investment, trading or regulatory decisions. |

## What each tier requires

| | **Tier 1 — low** | **Tier 2 — medium** | **Tier 3 — high** |
| --- | --- | --- | --- |
| **Review gate** | Self-service checklist. No meeting; the platform is notified, not consulted. | Platform review. AI Platform reviews the intake record and the placement before the workload is enabled. | Platform, Security and Compliance review. All three, jointly, on the record. |
| **Allowed provider set** | Any provider marked usable for Internal data in the classification matrix in `policies/`. | Providers marked usable for Confidential, and only under the data-residency and retention terms recorded in `docs/vendors/`. | Providers marked usable for Restricted only. In practice: models hosted in the Northgate Azure subscription, and the self-hosted model. No external provider. |
| **Logging mode** | Metadata only. | Metadata only by default. | Metadata only by default. |
| **Content logging** | Off. Enabling it requires a tier 2 approval and a DPIA reference on the workload record. | Off by default. Enabling it requires an explicit approval and a DPIA reference. | Off by default. Enabling it requires an explicit approval, a DPIA reference, and a stated retention period. |
| **Pilot duration** | None required. Two weeks if the consumer wants one. | Four weeks minimum in Pilot before production. | Eight weeks minimum in Pilot before production. Extending the pilot is the default response to thin evidence. |
| **Evidence before production** | Completed checklist, and gateway metadata for the pilot window if one ran. | Checklist; a sampled output review signed by the consuming function; spend against the budget; gateway policy decisions showing no denied-category attempts. | The tier 2 set, plus a human-override log showing the override path was exercised, a DPIA, a Security control review, and a Compliance position on record-keeping. |
| **Re-review cadence** | Annual. | Semi-annual. | Quarterly. |
| **Service acceptance signed by** | The consuming function's owner. Countersigned automatically by the intake record the CLI writes. | AI Platform and the consuming function's owner. | AI Platform, Security, Compliance and the consuming function's owner. Four signatures, no delegation. |

Metadata means: who called, when, which model, token counts, latency, policy decision,
cost. It does not mean prompt or completion bodies. Content logging is the separate switch
in the row below it, and it is off unless someone has signed for it.

The classification matrix in `policies/` is the authority on which provider may see which
data class. This table points at it; it does not restate it. `policies/` arrives in
Phase 3 — until it does, the tier 3 provider set above is the working rule.

## Worked examples

**Research summarisation over internal documents.** Summarises internal research notes for
the analyst who asked. Internal data (1), assistive — the analyst reads the summary (1),
internal audience (1), informational (1). Scores **1 / 1 / 1 / 1 — tier 1.** Self-service
checklist, annual re-review, metadata-only logging, any Internal-approved provider.

**Client-report drafting agent.** Drafts periodic client reports from confidential holdings
data; a relationship manager approves each draft before it is sent. Confidential including
client personal data (2), human approves each action (2), output leaves the firm in a
client report (2), operational (2). Scores **2 / 2 / 2 / 2 — tier 2.** Platform review,
four-week pilot, sampled output review as evidence, semi-annual re-review.

**Trade-idea generator touching MNPI.** Surfaces trade ideas from a corpus that includes
MNPI. Restricted data (3) — **tier 3, and the other three axes do not matter.** Even if it
is purely assistive (1), internal-only (1) and informational (1), the score is
3 / 1 / 1 / 1 and the highest axis sets the tier. Platform, Security and Compliance review;
Azure-hosted or self-hosted models only; eight-week pilot; quarterly re-review; four
signatures.

The third example is the point of the highest-axis rule. A workload that touches MNPI is a
tier 3 workload whatever else is true about it, because the failure mode is a control
breach, not a bad answer.

## Re-scoring

A workload is re-scored when any axis changes — a new data source, a new audience, an
approval step removed — and not only at the re-review cadence. The consuming function is
responsible for saying so; the platform is responsible for noticing when telemetry
disagrees with the recorded tier.

A tier can go down. It goes down the same way it went up: through the review gate for the
tier it is leaving, with the change recorded on the workload.

## Disputes

If the consuming function and the platform disagree on an axis, the workload runs at the
higher score until the disagreement is resolved. Escalation is to the accepting signatories
for the higher tier. There is no appeal that lets a workload run at a lower tier while the
argument is open.
