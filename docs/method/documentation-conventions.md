# Documentation conventions

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-21
- **Out of scope** — the ADR format, which is in [`adr-template.md`](adr-template.md); the
  modelling rules, which are in [`c4-conventions.md`](c4-conventions.md); code comments,
  docstrings and API reference material, which follow the language's own conventions and
  are not documents in this sense.

## The header block

Every document in this repository opens with a level-one heading and then this block, in
this order, with no prose between them:

```markdown
# Title

- **Owner** — AI Platform
- **Status** — Active
- **Last reviewed** — 2026-09-21
- **Out of scope** — what this document deliberately does not cover.
```

| Field | What it means |
| --- | --- |
| **Owner** | The function accountable for the document being true, matching `CODEOWNERS` — `AI Platform`, `Security`, `FinOps`, `Service Management`, or a pair such as `AI Platform / Security`. Never a person's name: people change roles, and a document owned by someone who has moved on is orphaned without anyone noticing. |
| **Status** | Where the document is in its own life. Values below. |
| **Last reviewed** | ISO date, `YYYY-MM-DD`. The date a human last confirmed the content is still true — not the date of the last commit. |
| **Out of scope** | What the document deliberately does not cover, so a reader who wants that stops looking here. Point at where it does live where you can. |

### Status values

| Value | Meaning |
| --- | --- |
| `Draft` | Being written. Not yet something to rely on. |
| `Active` | Current. This is what we do. |
| `Deprecated` | No longer what we do. Kept because something still references it or because the history matters. Say what replaced it. |
| `Planned` | Reserved for a directory `README.md` describing a directory whose contents do not exist yet. Not for ordinary documents. |

ADRs use a different set — `Proposed`, `Accepted`, `Superseded by NNNN`, `Deprecated` —
and services use a third, the build status and lifecycle stage in the root `README.md`.
Three vocabularies, three purposes, no mixing.

## Last reviewed and staleness

Update **Last reviewed** on any substantive edit, in the same pull request as the edit.
`CONTRIBUTING.md` requires this and CI will not catch it for you.

A substantive edit is one that changes what a reader would do. A typo fix, a reflowed
paragraph or a corrected link is not. Do not update the date to keep a document looking
fresh — an accurate old date is more useful than a false recent one.

**Anything with a Last reviewed date older than 12 months is stale by definition.** Not
"probably out of date", not "worth a look" — stale. A stale document has to be reviewed
and re-dated or marked `Deprecated`; there is no third option and no grace period.

## Every service document has an Out of scope section

Any document describing a service, a capability or a directory must state what it does not
cover. This is the header field, and for longer documents it may also be a closing section
that goes into more detail.

The reason is operational rather than editorial: the expensive failure is a reader who
assumes a control exists because a document nearby talks about controls. Naming the gap is
cheaper than the assumption.

## Spelling and language

British spelling throughout: *organisation*, *authorisation*, *behaviour*, *summarise*,
*licence* as the noun, *catalogue*. English only, including technical terms.

Two exceptions, because changing them would break things: identifiers in code, config and
DSL keep whatever spelling the tool uses, and quoted vendor product names keep the vendor's
spelling.

Write in the present tense about what the platform does, and in plain declarative
sentences. Avoid filler and avoid hedging: if something is uncertain, say what is uncertain
and why, rather than softening the whole paragraph.

## File naming

- Markdown files are kebab-case: `risk-tiering.md`, `c4-conventions.md`.
- The exceptions are the repository-root files that tooling expects in upper case:
  `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`, `CODEOWNERS`, `LICENSE`.
- Directory `README.md` is the index for that directory. Nothing else is named `README.md`.
- ADRs are `NNNN-kebab-title.md` and nothing else — see [`adr-template.md`](adr-template.md).
- No spaces, no underscores, no dates in filenames. A date in a filename is a version
  control system that does not work.

## Links

Links between documents in this repository are **relative** — `../method/risk-tiering.md`,
not an absolute path and not a `github.com` URL. Relative links survive a fork, a rename of
the repository and a local checkout; absolute ones do not.

Link to the file, not to a heading, unless the heading is the point. Heading anchors break
silently when headings are reworded.

External links are fine and should name what they point at, so the link text still tells a
reader something when the target has moved.

## Diagrams

Diagrams are code. Architecture diagrams are Structurizr DSL under `docs/architecture/`,
rendered in CI. See [`c4-conventions.md`](c4-conventions.md) for the modelling rules.

For a small non-architecture diagram — a state machine, a decision flow, a sequence — a
fenced Mermaid block inside the document is acceptable and preferred over a separate file.
It diffs, it reviews, and it travels with the prose it explains.

Hand-drawn images, whiteboard photographs, screenshots of diagramming tools and exported
drawing-tool files are not accepted anywhere in this repository.

## Markdown mechanics

- Linted by `markdownlint-cli2` through pre-commit. Run `pre-commit run --all-files` before
  opening the pull request.
- Line length is not enforced. Wrap where it reads well and keep the wrapping stable, so
  diffs stay small.
- One level-one heading per file, and it is the title.
- Fenced code blocks always declare a language. Use `text` when there is no better one.
- Tables for anything that is genuinely tabular, prose for anything that is not. A table of
  one column is a list.
