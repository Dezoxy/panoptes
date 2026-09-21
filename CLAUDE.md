# Panoptes — instructions for coding agents

Panoptes is a shared AI platform for a regulated asset manager: a model gateway, a
controls plane, telemetry and cost attribution, a risk-based onboarding lifecycle and
Copilot estate administration. Northgate Asset Management is a fictional tenant — the
name exists so that entitlements, data classes and rollout plans can be written for a
regulated asset manager instead of for a sandbox; Panoptes is not deployed at any
company.

## Non-negotiables

- Never use the words portfolio, showcase, demo, tutorial or interview in any file.
- Never name a real company. Northgate Asset Management is the only tenant name.
- Dry operational tone. British spelling throughout.
- Every document carries the same header block: Owner, Status, Last reviewed, Out of
  scope.
- An ADR without rejected alternatives is not accepted. Record what was turned down, and
  what would have to change for the decision to be revisited.
- Conventional commits, `type(scope): summary`, imperative mood, no trailing period.
  Scopes: `gateway`, `iac`, `policies`, `telemetry`, `automation`, `docs`, `copilot`,
  `finops`, `vendors`, `runbooks`, `ci`, `chore`. Types and breaking-change rules are in
  `CONTRIBUTING.md`.
- Diagrams are code: Structurizr DSL under `docs/architecture/` only. Hand-drawn images,
  whiteboard photographs and exported drawing-tool files are not accepted.
- No secrets in the repository. `.context/` is private and gitignored; never read its
  contents into a committed file.

## Architecture authoring

- For Structurizr model/view work, read
  `.agents/skills/architecture-views/SKILL.md`.
- For architecture documentation beyond diagrams, read
  `.agents/skills/architecture-docs/SKILL.md`. Use both for mixed requests.
- These skills come from architecture-base. Apply this repo's own evidence, paths,
  tool pins and checks. Do not copy the base repo's fictional Payment Platform.
- Use automatic layout and verify rendered readability. Export PNG/SVG manually;
  do not add export automation unless requested.
- Title documents under `docs/architecture/overview/` with `##`, not `#`.
  Structurizr hides a level-1 heading from the page and the navigation, and the
  PDF will not show you the problem. No check enforces this here yet, so verify it
  by hand until one exists under `checks/`.

## Working rules

- Small commits, one concern each. If the summary needs an "and", split it.
- Run `pre-commit run --files <the files you touched>` before you finish, and
  `pre-commit run --all-files` before opening a pull request.
- Do not edit `CHANGELOG.md` unless you are asked to.
- Label what runs and what is only documented, honestly. Nothing is deployed and no
  tenant is simulated: the output of a dry-run script is the call it would have made,
  not evidence that a control is in force. Never write as though the tenant exists.
- Update the docs a change falsifies in the same branch, including **Last reviewed**.

## Pointers

- `.claude/rules/` — engineering rules: code review, coding style, security, testing,
  git and merge discipline, with `python/` for Python-specific rules.
- `.claude/skills/` — skills, mirrored in `.agents/skills/` for non-Claude agents.
- `docs/method/` — templates and the design, review and documentation process.
