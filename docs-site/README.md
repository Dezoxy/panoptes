# Documentation site

- **Owner** — AI Platform
- **Status** — Planned
- **Last reviewed** — 2026-09-21
- **Out of scope** — the documents themselves, which stay in their own directories and are
  published from there; the self-service portal (`portal/`); and any public site — this is
  internal only.

Sources and build configuration for `docs.panoptes.northgate.internal`: the site generator,
navigation, search, and the pipeline that renders the Markdown already in this repository
plus the architecture diagrams rendered into `docs/architecture/generated/`.

The site is a view over this repository, never a second copy. A page that exists only on
the site is a page nobody reviews.

Arrives in **Phase 5**, alongside the portal.
