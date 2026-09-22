# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Until the first tagged release, `main` is the only supported version and the public
surface may change without a major version bump.

## [Unreleased]

### Added

- Repository scaffold: licence, ownership, security policy, contribution rules and
  changelog.
- Control gates: pre-commit hook suite (formatting, linting, type checking, Terraform
  static analysis, secret scanning, commit-message validation) and the CI workflow that
  runs it on every pull request and push to `main`.
- README with scope, service catalogue and status legend.
- Method docs: ADR template with mandatory rejected alternatives, C4 conventions,
  three-tier four-axis risk rubric, RFC and review process, documentation conventions.
- ADR-0001 to ADR-0004: decision records, hybrid topology and placement, LiteLLM model
  gateway, CI on GitHub Actions.
- ADR-0005: lab tier on Azure Container Apps with Azure-native observability; on-prem tier
  documented as the exit environment.
- C4 model in Structurizr DSL with a CI workflow that validates, inspects and exports it.
- Directory skeleton with per-directory scope, owning function and delivery phase.
- `panoptes_platform` package and `panoptes` CLI skeleton (uv, typer, mypy strict).
- Agent instructions, engineering rules and architecture authoring skills.
- Platform responsibility matrix: per-layer ownership and Supported / Tolerated /
  Forbidden tool statuses; golden-path workload template added to the Phase 3 scope.
- Azure control plane: Key Vault, Foundry account with two pinned deployments, Entra
  groups and gateway app registration, Log Analytics, Application Insights, Azure
  Monitor workspace.
- Gateway config as code: five routes with data-class and residency metadata, two
  fallback groups, JWT and virtual-key auth, metadata-only logging; image build
  workflow pushing to ACR through OIDC; Compose exit-path stack; config tests.
- Gateway live in the lab (2026-09-22): first chat completions through `chat-default`,
  `azure-gpt-4o`, `chat-restricted` and `openrouter-mistral`; bad key rejected with 401;
  audit spans in Application Insights with no prompt or completion text.
- Container Apps environment, PostgreSQL add-on, gateway app with OpenTelemetry
  sidecar, Key Vault references, always_on switch; Azure Container Registry with
  managed-identity pull and GitHub OIDC push.
- Work admin account (`admin@azuretomhorvath.onmicrosoft.com`) for day-to-day tenant
  administration, Global Administrator and subscription Owner, with the personal
  account kept as break-glass; Key Vault and platform-group grants for both operators
  addressed by object id rather than by the CLI's signed-in account.
