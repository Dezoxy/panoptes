# Platform responsibility matrix

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-22
- **Out of scope** — how to build an agent. The platform does not prescribe frameworks,
  prompt patterns or retrieval designs, and this document does not teach them.

An agentic workload has eight layers. For each one this matrix names the owner, what the
platform provides, what the consuming team decides, and where example tools sit. Read it
before intake: it settles most of the questions the intake record would otherwise raise.

## Tool statuses

| Status | What it means |
| --- | --- |
| **Supported** | The platform runs or integrates the tool and will help you with it. It appears in platform runbooks and the platform carries the operational burden. |
| **Tolerated** | You may use it. The platform does not operate it, will not debug it and holds no runbook for it. Any model call it makes still goes through the gateway. |
| **Forbidden** | It bypasses a platform control. The control is named in the row, so the condition for lifting the status is explicit. |

Tolerated is not a warning. Most of the agent ecosystem sits there by design: the platform
governs the model call and the data class, not the consuming team's choice of library.

## 1. Use case and planning

**Owner** — Consumer. **Platform provides** — the intake template, the risk rubric in
[`../method/risk-tiering.md`](../method/risk-tiering.md), and the four lifecycle stages.
**Consumer decides** — the problem, the success measure, and which function owns the
outcome.

| Tool | Status | Reason |
| --- | --- | --- |
| Jira, Confluence, Notion, Linear, Miro | Tolerated | The platform reads the intake record, not the tool the team planned in. |

## 2. Data and knowledge

**Owner** — Consumer, shared with the platform for classification. **Platform provides** —
the data classification scheme (Public / Internal / Confidential / Restricted, the last
including MNPI) and the classification-to-provider matrix in `policies/`. **Consumer
decides** — sources, retrieval design and vector store.

| Tool | Status | Reason |
| --- | --- | --- |
| Azure AI Search | Supported | In the firm's own subscription and Entra-integrated, so entitlements are the ones the platform already enforces. |
| Elasticsearch, Neo4j | Tolerated | Self-operated by the consuming team; the platform does not run or tune them. |
| Pinecone, Weaviate cloud | Tolerated for Public and Internal; Forbidden for Confidential and Restricted | A third-party store outside the estate. Forbidden for the higher classes until a vendor record exists in [`../vendors/README.md`](../vendors/README.md) covering residency, retention and exit. |
| Microsoft Fabric | Tolerated | A data estate concern; the platform consumes what it produces rather than operating it. |

## 3. Models and reasoning

**Owner** — Platform. **Platform provides** — the gateway, the allowed provider set per
data class, fallback, quotas, audit, version pinning and the provider-change playbook.
**Consumer decides** — which allowed model to call, and the prompt design.

| Tool | Status | Reason |
| --- | --- | --- |
| Azure AI Foundry deployments (OpenAI and other models) | Supported | Own-tenancy hosting, which is what the tier 3 provider rule requires. |
| Anthropic Claude via the gateway | Supported | Routed, rate-limited and audited like every other provider. |
| OpenAI via the gateway | Supported | Same routing, quota and audit path. |
| Self-hosted Ollama via the gateway | Supported, and the Restricted route | Runs on the firm's own hardware, so Restricted data never leaves it. |
| Mistral or Llama as Foundry deployments | Supported | Supported because of where they run, not because of who trained them. |
| Google Gemini | Forbidden | No vendor record and no gateway route. Lift it when both exist. |
| A provider API key held by the application | Forbidden | Bypasses the single control point: no entitlement check, no quota, no attribution, no audit record. Every model call goes through the gateway — see [`../../adr/0003-model-gateway-litellm.md`](../../adr/0003-model-gateway-litellm.md). |

## 4. Tools and integrations

**Owner** — Consumer, shared with the platform for anything reaching a system of record.
**Platform provides** — a registry of approved MCP servers and connectors (Phase 3), the
connector allow-list for Copilot Studio (Phase 2), and the autonomy axis of the risk
rubric. **Consumer decides** — which tools the agent may call.

| Tool | Status | Reason |
| --- | --- | --- |
| MCP servers listed in the registry | Supported | Reviewed once, centrally, and re-reviewed on the registry's cadence. |
| MCP servers not in the registry | Tolerated at tier 1 only | Unreviewed reach into other systems. Above tier 1 the autonomy axis makes that a review gate, not a preference. |
| n8n, Zapier, Workato, MuleSoft as workflow engines | Tolerated | Orchestration the consuming team operates; no platform control is involved. |
| The same tools as a route to a model provider | Forbidden | Their built-in LLM nodes call providers directly and bypass the gateway. Point them at the gateway endpoint instead. |

## 5. Agent design and orchestration

**Owner** — Consumer. **Platform provides** — nothing prescriptive. A golden-path workload
template, scaffolded by `panoptes onboard scaffold` (Phase 3), arrives with the gateway
client, OpenTelemetry and policy hooks already wired. **Consumer decides** — the framework,
the control flow and the state model.

| Tool | Status | Reason |
| --- | --- | --- |
| LangGraph, OpenAI Agents SDK, Microsoft AutoGen, Semantic Kernel, CrewAI | Tolerated, conditional | Use any of them, provided the model client points at the gateway. The platform has no view on which is better. |
| Copilot Studio agents | Supported | Administered as part of the Copilot estate and covered by its controls. |

## 6. Evaluation and guardrails

**Owner** — Shared. **Platform provides** — policy enforcement at the gateway
(classification, entitlement, quota), the evidence the production-readiness review needs —
a sampled output review at tier 2, a human-override log at tier 3 — and metadata-only audit
records. **Consumer decides** — application-level guardrails and the evaluation suite.

| Tool | Status | Reason |
| --- | --- | --- |
| promptfoo | Supported | The evaluation format the production-readiness review accepts. |
| DeepEval, Ragas | Tolerated | Useful; the platform neither runs them nor reads their output as evidence. |
| Guardrails AI | Tolerated | An application-layer control, not a substitute for the gateway's. |
| LangSmith | Tolerated for tracing, otherwise Forbidden | Allowed only if traces stay in the EU and carry no Restricted data. Outside those two conditions it exports regulated content to a third party. |

## 7. Deployment and runtime

**Owner** — Platform for placement, Consumer for the workload. **Platform provides** — the
placement rules in [`../../adr/0002-hybrid-topology-and-placement.md`](../../adr/0002-hybrid-topology-and-placement.md),
Kubernetes namespace conventions, Azure Container Apps as the production target, and images
built in CI. **Consumer decides** — nothing about placement; everything about the code.

| Tool | Status | Reason |
| --- | --- | --- |
| Docker, Kubernetes | Supported | The build and lab-tier runtime the platform already operates. |
| Azure Container Apps | Supported | The documented production placement. |
| Microsoft Foundry Agent Service | Supported, conditional | Supported once a gateway route exists for it. Until then it has no approved path to a model and cannot be used. |
| Amazon Bedrock AgentCore, Vertex AI Agent Engine | Forbidden | Outside the estate, with no exit-path or data-residency review behind them. |

## 8. Observability and monitoring

**Owner** — Platform. **Platform provides** — the OpenTelemetry collector endpoint, Grafana
dashboards per team, cost attribution and budget alerts. **Consumer decides** —
application-level spans and what they are named.

| Tool | Status | Reason |
| --- | --- | --- |
| OpenTelemetry | Supported | The instrumentation contract between a workload and the platform. |
| Grafana | Supported | Where the per-team dashboards and budget alerts live. |
| LangSmith, Arize Phoenix | Tolerated, conditional | Application tracing under the same condition as layer 6: EU-resident traces, no Restricted data. |
| Datadog | Forbidden | A second observability estate, at a second cost, with no vendor record covering residency. Lift it when one exists. |

## Changing this matrix

A tool moves between statuses through the RFC process in
[`../method/rfc-and-review.md`](../method/rfc-and-review.md). Raise one when a tool you need
is Forbidden, when a Tolerated tool has become load-bearing enough that the platform should
operate it, or when a Supported tool no longer earns the support.

Every Forbidden entry names the control it bypasses, so the condition for lifting it is
written down and the argument is about whether that condition has been met.
