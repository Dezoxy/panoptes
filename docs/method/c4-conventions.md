# C4 conventions

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-22
- **Out of scope** — the model itself, which lives in `docs/architecture/`; sequence and
  dynamic views, which are optional and unregulated here; UML, ArchiMate and any other
  notation. This document fixes how we model, not what the model says.

## Source of truth

The architecture is Structurizr DSL under `docs/architecture/`. The DSL is the source of
truth for every diagram in this repository. Prose describes the model; it does not replace
it, and where the two disagree the DSL is right and the prose is stale.

```text
docs/architecture/
├── workspace.dsl        # entry point; stays at this level
├── model/               # !include fragments only
│   ├── people-systems.dsl
│   ├── containers.dsl
│   ├── deployment.dsl
│   ├── views.dsl
│   └── styles.dsl
└── generated/           # rendered exports; gitignored
```

`workspace.dsl` stays at the top of `docs/architecture/` and does nothing but declare the
workspace and `!include` the fragments in `model/`. Structurizr resolves include paths
relative to the including file and refuses to climb above it, so a fragment cannot reach
back out of `model/` — keep every fragment self-contained and let `workspace.dsl` do the
assembly.

Split fragments by role, not by size. One file per view type, one for people and external
systems, one for containers, one for deployment, one for styles. A fragment that needs a
second fragment's identifiers is a sign the split is in the wrong place.

## The seven layers

Panoptes is described in seven layers. They are a way of talking about the platform, not a
C4 concept, so they have to be mapped onto C4 elements deliberately:

| Layer | How it appears in the model |
| --- | --- |
| Consumers | People and external software systems outside the Panoptes boundary. Never containers. |
| Model gateway | Containers. `panoptes-gateway` is one; anything it cannot be deployed without is another. |
| Providers | External software systems. Azure AI Foundry, Anthropic and OpenAI are systems we call, not systems we build. The self-hosted model is a container, because we run it. |
| Controls plane | A group of containers — policy engine, entitlement store, evidence collector. |
| Telemetry and FinOps | A group of containers — collector, metering, storage, dashboards. |
| Lifecycle | Modelled only where it has a runtime surface: the `panoptes` CLI and the portal. The review gates themselves are process and belong in `docs/onboarding/`, not in the model. |
| Copilot estate | External software systems, administered rather than built. They appear in the system context view and in deployment; they have no containers of ours inside them. |

The rule underneath the table: **a layer becomes a container when it has something you can
deploy and restart. It becomes a group when it is several such things that share an
owner and a boundary. Otherwise it is prose.** Do not create an empty container to make a
layer visible.

Groups are declared in the container view for logical grouping and in the deployment view
for physical grouping. The two groupings do not have to agree, and usually will not —
that disagreement is the interesting part of the architecture.

## Deployment relationships

In the deployment model a relationship attaches to a container instance, a software system
instance or an infrastructure node, never to a deployment node. A deployment node renders as a
boundary, not as a laid-out element: the DSL parser and `structurizr inspect` accept the edge,
but the browser's automatic layout fails on the whole view with a `rank` error and every
boundary collapses onto one corner. Point the edge at the instance inside the node instead,
using its hierarchical identifier.

## Trust boundaries

Trust boundaries are expressed as **deployment-view groups**, not as styling, not as a
note, and not as a box drawn around containers in the container view. There are four:

- `Azure subscription` — the Northgate subscription hosting the control plane and the
  hosted models.
- `On-prem Kubernetes` — the `panoptes` namespace: gateway, self-hosted model,
  observability stack.
- `External providers` — everything reached over the public internet.
- `Consumer network` — where the calling workloads run.

Every relationship that crosses one of these groups must name two things in its
description: **the protocol** and **the identity used**. Not the transport alone, and not
"authenticated".

```text
consumer -> gateway "Submits completion request [HTTPS, Entra ID workload identity]"
gateway -> anthropic "Forwards prompt [HTTPS, provider API key from Key Vault]"
operator -> cluster "Administers [HTTPS via zero-trust proxy, Entra ID + device posture]"
```

A cross-boundary relationship with no identity in its description is an incomplete model,
and reviewers should reject it. Inside a boundary, the protocol alone is enough.

## Required views

Every system in the workspace carries three views, and a pull request that adds a system
without them is incomplete:

1. **System context** — the system, its users, and the external systems it depends on.
2. **Container** — what runs inside the system boundary, grouped by layer.
3. **Deployment** — which boundary each container runs in, for each environment modelled.

Anything else — component views, dynamic views, filtered views — is allowed where it earns
its place and is not required anywhere.

## Layout

Automatic layout only. No hand-placed coordinates, no `x`/`y` on elements, no committed
`workspace.json` carrying a saved layout. If a view is unreadable under automatic layout,
the view is too large: split it, filter it, or accept that the diagram is telling you the
architecture is too tangled.

This is a maintenance decision, not an aesthetic one. Hand-placed coordinates rot on the
first structural change and make every diff a layout diff.

## Exports and rendering

Exports go to `docs/architecture/generated/`, which is gitignored and rendered in CI. Do
not commit rendered output. The generated directory is excluded from pre-commit,
markdownlint and yamllint.

Render locally when you want to look at something; the CI render is the one that counts.
A pull request that changes the DSL and fails the render fails the build.

## No hand-drawn images

Whiteboard photographs, screenshots of diagramming tools, exported `.drawio`, `.vsdx` and
`.png` architecture pictures are not accepted in this repository, in any directory, for
any reason — including "just for the README". They cannot be diffed, cannot be reviewed
line by line, and drift from the system silently.

The one narrow exception is a screenshot used as **evidence** of a third-party console
state, which belongs in `evidence/` and is not an architecture diagram.
