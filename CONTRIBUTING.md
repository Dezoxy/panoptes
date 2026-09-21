# Contributing

Working agreement for the Panoptes repository. It applies to every change, including
one-line ones.

## Branches and pull requests

- Branch off `main`. Keep branches short-lived; rebase rather than let them age.
- One concern per commit. If a commit needs "and" to describe it, split it.
- Open a pull request against `main`. Merge with squash or rebase; no merge commits.
- CI must be green and CODEOWNERS review must be resolved before merge.
- Direct pushes to `main` are blocked by the `no-commit-to-branch` pre-commit hook.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/). Format:
`type(scope): summary`, imperative mood, no trailing period.

Allowed types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`,
`revert`.

Allowed scopes: `gateway`, `iac`, `policies`, `telemetry`, `automation`, `docs`, `copilot`,
`finops`, `vendors`, `runbooks`, `ci`, `chore`.

Breaking changes use `!` after the scope and a `BREAKING CHANGE:` footer explaining the
migration. The `commit-msg` hook enforces types and scopes; it cannot check whether the
summary is useful, so that is on you.

## Local setup

```sh
pip install pre-commit
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

Run the whole suite before opening a pull request:

```sh
pre-commit run --all-files
```

The Terraform hooks need `terraform`, `tflint`, `trivy` and `checkov` on `PATH`. CI
installs them; locally, install what you need for the area you are touching.

## Decision records

Any decision that affects **where something runs, which provider it uses, where a security
boundary sits, or how data is handled** needs an ADR in `adr/` before the implementing pull
request merges. Use the template in `docs/method/`.

An ADR without rejected alternatives is not accepted. "We chose X" is a note; "we chose X
over Y and Z, because of these trade-offs" is a decision record. State what would have to
change for the decision to be revisited.

Small implementation choices inside an already-decided boundary do not need an ADR. If you
are unsure, open the ADR — a rejected ADR is cheaper than an undocumented boundary.

## Documentation

Every workload or service document carries these sections:

- **Owner** - the function accountable for it, matching `CODEOWNERS`.
- **Status** - proposed, active, deprecated, or retired.
- **Last reviewed** - an ISO date. A document nobody has reviewed in a year is stale by
  definition.
- **Out of scope** - what the document deliberately does not cover, so readers stop looking.

Diagrams are code. Architecture diagrams are Structurizr DSL under `docs/architecture/`,
rendered in CI into `docs/architecture/generated/` (gitignored). Hand-drawn images,
screenshots of whiteboards and exported drawing-tool files are not accepted: they cannot be
diffed, reviewed or kept in step with the system they describe.

Markdown is linted by `markdownlint-cli2`. Line length is not enforced; wrap where it reads
well.

## Before you open the pull request

- `pre-commit run --all-files` passes.
- New or changed behaviour has tests.
- Docs touched by the change are updated in the same pull request, including
  **Last reviewed**.
- An ADR exists if the change crosses one of the thresholds above.
