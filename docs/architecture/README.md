# Architecture

- **Owner** — AI Platform
- **Status** — Draft
- **Last reviewed** — 2026-09-21
- **Out of scope** — model internals and evaluation; the Microsoft 365 tenant
  itself; consumer workload design; Terraform and cluster platform detail, which
  belong in `iac/`. Decisions live in `adr/`, not here: this model records what
  the platform is, not why each choice was made.

The C4 model for Panoptes, written in Structurizr DSL. It is a first cut. It
describes the target shape of the platform, not a running system — see the
status legend in the [repository README](../../README.md#status-legend) for what
each state means.

## Model

| File | What it holds |
| --- | --- |
| [workspace.dsl](workspace.dsl) | Entry point. Includes the fragments below and imports `overview/` as the Documentation tab. |
| [model/people.dsl](model/people.dsl) | The five roles that use or operate the platform. |
| [model/systems.dsl](model/systems.dsl) | Software systems outside Panoptes: providers, identity, the Copilot estate. |
| [model/containers.dsl](model/containers.dsl) | Panoptes and its containers, grouped by layer. |
| [model/relationships.dsl](model/relationships.dsl) | Every relationship, in call order, each naming its protocol and identity. |
| [model/deployment.dsl](model/deployment.dsl) | Where each container runs across Azure, the on-prem cluster and the provider APIs. |
| [model/views.dsl](model/views.dsl) | The four views. |
| [model/styles.dsl](model/styles.dsl) | This repository's layer and group colours. |
| [model/styles-shared.dsl](model/styles-shared.dsl) | Shared palette and tag meanings. Copied unchanged from `architecture-base`; fix it there, then copy it back. |

Fragments are split further than the base, which keeps people and external
systems in one file and relationships alongside the containers that own them.
Panoptes has more of both, and its relationships mostly cross layers, so they
read better in one ordered list.

## Views

Every view uses automatic layout. Nothing in this workspace carries hand-placed
coordinates.

| View | Question it answers |
| --- | --- |
| SystemContext | Who uses Panoptes, and what does it depend on? |
| Containers | What are the building blocks, layer by layer? |
| ChatCompletion | What happens on one chat completion request? |
| PlatformDeployment | Where does each part run, and which boundaries does a call cross? |

The written overview — purpose, layers, trust boundaries, and the
documented-versus-running rule — is in [overview/README.md](overview/README.md).
It becomes the Documentation tab when the workspace is rendered, so its sections
start at `##`: Structurizr hides a level-1 heading.

## Validate and export locally

Both commands need Docker and use the same image CI pins. Run them from the
repository root.

```sh
# Parse the workspace. Silent on success; non-zero exit and a line number on failure.
docker run --rm -v "$PWD/docs/architecture:/w:ro" \
  structurizr/cli:2025.11.09 validate -workspace /w/workspace.dsl

# Model findings. Exits non-zero on any finding, so read the output rather than the code:
# only an ERROR line needs fixing.
docker run --rm -v "$PWD/docs/architecture:/w:ro" \
  structurizr/cli:2025.11.09 inspect -workspace /w/workspace.dsl

# Export every view as PlantUML into generated/, which is gitignored.
mkdir -p docs/architecture/generated && chmod 777 docs/architecture/generated
docker run --rm -v "$PWD/docs/architecture:/w:ro" -v "$PWD/docs/architecture/generated:/out" \
  structurizr/cli:2025.11.09 export -workspace /w/workspace.dsl -format plantuml -output /out
```

To browse the rendered views, run the Structurizr Lite image against this
directory and open `http://localhost:8080/workspace/1`. That image renders the
Documentation tab and the diagrams; the CLI above does not.

`.github/workflows/architecture.yml` runs `validate` and `export` on every pull
request that touches `docs/architecture/**`, and uploads the exports as an
artifact. Exports are never committed.

## Decisions

Architecture decision records live in [`adr/`](../../adr/) at the repository
root, outside this directory, so they are not imported into the workspace with
`!adrs`. That directory arrives with the next scaffold step; until it does, this
model is unjustified by design — every placement choice it shows is still open.

An ADR is expected to settle, at least: where the gateway runs (self-hosted
versus the documented APIM node), which metrics store sits behind Grafana, and
whether the entitlement source stays a set of Entra ID groups.
