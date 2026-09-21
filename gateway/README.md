# Gateway

- **Owner** — AI Platform
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — the provider contracts behind the routes (`docs/vendors/`), the policy
  rules the gateway evaluates (`policies/`), and the infrastructure it runs on (`iac/`).

Configuration for `panoptes-gateway`: routing rules, the provider and model catalogue,
fallback chains, per-consumer quotas and rate limits, and the request and response
transforms applied at the edge. Every consumer call to a model passes through here, so this
directory is also where the audit trail is defined — what is recorded on each call and
what is deliberately not.

Nothing here is a secret. Provider credentials live in Key Vault and are referenced, never
committed; `gitleaks` runs on this path like every other.

Arrives in **Phase 1**, with the gateway itself. It is the first thing that runs.
