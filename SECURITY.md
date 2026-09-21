# Security policy

## Supported versions

Only `main` is supported. There are no release branches and no backports. Fixes land on
`main` and are picked up by the next deployment.

## Reporting a vulnerability

Use GitHub private vulnerability reporting on this repository:
**Security -> Advisories -> Report a vulnerability**. Do not open a public issue for a
suspected vulnerability, and do not attach credentials or customer data to a report.

Include the affected path, the version or commit you tested, what you observed, and the
steps to reproduce it. A proof of concept against your own environment is welcome; do not
test against shared or production infrastructure.

We acknowledge a report within **3 working days** and follow up with an assessment and a
remediation plan. If a report turns out to be out of scope we say so and explain why.

## Scope

In scope:

- Gateway configuration and routing rules (`/gateway/`)
- Policy definitions and their enforcement logic (`/policies/`)
- Infrastructure as code and the landing-zone definitions it produces (`/iac/`)
- Automation and scheduled jobs (`/automation/`)
- The telemetry pipeline and anything it exports (`/telemetry/`)

Out of scope:

- Vulnerabilities in third-party model providers' own services. Report those to the
  provider; if the issue changes how Panoptes should be configured, open a normal issue
  here describing the configuration change.
- Findings that only apply to a fork or a modified deployment of this repository.
- Missing hardening that is documented as an accepted risk in an ADR.

## Secret handling

No secrets in the repository. Not in code, not in configuration, not in test fixtures, not
in commit history.

- `gitleaks` runs as a pre-commit hook and again in CI on the full history of the branch.
- Credentials live in Azure Key Vault. Kubernetes secrets are sourced from Key Vault, never
  authored by hand and never committed.
- Example configuration uses `*.example` files with placeholder values.

Any secret that reaches a commit is treated as a **rotation event**, not a cleanup task:
rotate the credential first, then remove it from the repository and history. A value that
has been pushed is considered disclosed regardless of how quickly it was reverted.
