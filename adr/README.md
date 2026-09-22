# Architecture decision records

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-22
- **Out of scope** — the template and the field-by-field guidance, which live in
  `../docs/method/adr-template.md`; the threshold for needing an ADR at all, which is in
  `../CONTRIBUTING.md` and `../docs/method/rfc-and-review.md`; the architecture the
  decisions describe, which is modelled in `../docs/architecture/`.

## Purpose

This directory holds the reasons. The model in `docs/architecture/` says what exists and
how it connects; the documents elsewhere say what is required of it; these records say why
each significant choice was made, what else was on the table, and what the choice cost.

An ADR is written when a change decides **where something runs, which provider it uses,
where a security boundary sits, or how data is handled**. Small implementation choices
inside an already-decided boundary do not get one.

## Filename and numbering

- `NNNN-kebab-title.md`, four zero-padded digits, starting at `0001`.
- The number is read from the first four characters of the filename. It is not stored
  anywhere else.
- Numbers are allocated on merge. Two ADRs racing for the same number means the second to
  merge renumbers.
- A merged ADR is never renumbered, rewritten in substance, or deleted. Superseding it is
  the only way to change it.

## Status lifecycle

| Status | Meaning |
| --- | --- |
| `Proposed` | Open for review. Not binding. |
| `Accepted` | Binding. The platform is expected to match it, and a divergence is a defect. |
| `Superseded by NNNN` | Replaced by a later decision. Kept for the history. |
| `Deprecated` | No longer binding, not replaced — the context it addressed is gone. |

The status is the first word of the first non-empty line under `## Status`. Links to other
ADRs sit in the same section, before `## Context`.

## Rejected alternatives are not optional

**An ADR without a `Rejected alternatives` section is not accepted.** Each option that lost
needs two things recorded: why it lost, and the condition under which it would be
revisited. "We chose X" is a note. "We chose X over Y and Z, for these reasons, and here is
what would make us look at Y again" is a decision record.

This is the section that makes an ADR worth reading two years later, and it is the one
that gets dropped first when someone is in a hurry. The ADR linter in `../checks/` will
enforce it once that directory lands; until then it is enforced in review.

## Index

<!-- Entries are added as ADRs land. One row per file, newest last. -->

| Number | Title | Status | Date |
| --- | --- | --- | --- |
| 0001 | [Record architecture decisions as ADRs in this repository](0001-record-architecture-decisions.md) | Accepted | 2026-09-21 |
| 0002 | [Run a hybrid topology with the control plane in Azure and the gateway on-prem](0002-hybrid-topology-and-placement.md) | Accepted | 2026-09-21 |
| 0003 | [Run the model gateway on LiteLLM, configured as code](0003-model-gateway-litellm.md) | Accepted | 2026-09-21 |
| 0004 | [Run CI/CD on GitHub Actions, with portable pipelines](0004-ci-on-github-actions.md) | Accepted | 2026-09-21 |
| 0005 | [Run the lab tier on Azure Container Apps](0005-lab-tier-on-azure.md) | Accepted | 2026-09-22 |

## A note on the Structurizr importer

Structurizr's `!adrs` directive parses **every** Markdown file in the directory it is
pointed at as an ADR, including this one. If `!adrs` is ever pointed at `adr/`, either this
index moves into `docs/architecture/README.md` or the ADRs move into a subdirectory that
contains nothing else. Decide that when the workspace is wired up, not by accident.
