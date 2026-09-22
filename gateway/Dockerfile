# panoptes-gateway image.
#
# Base image pinned deliberately (ADR-0003: "version pinning and a canary route are
# mandatory, not optional"). LiteLLM's Docker tagging moved to plain semver in v1.84.0
# (main-v1.xx.y-stable is the deprecated pre-1.84 scheme); v1.102.0 is the current
# stable release, verified present via `docker manifest inspect
# ghcr.io/berriai/litellm:v1.102.0` on 2026-09-22 (amd64 and arm64 both published).
# Bump this tag as its own pull request.
FROM ghcr.io/berriai/litellm:v1.102.0

WORKDIR /app

# Config as code (ADR-0003): the route table, fallback chains and JWT/logging controls
# ship baked into the image rather than being mounted or edited at runtime.
COPY config.yaml /app/config.yaml

# The base image's default user is root. Chainguard's wolfi-base (what this image is
# built on) also ships a "nonroot" account (uid/gid 65532) with read and execute on
# everything under /app, which is all the proxy process needs — verified by running
# `litellm --help` as that user against this image on 2026-09-22.
USER nonroot

EXPOSE 4000

# /health/liveliness needs no auth and returns 200 ("I'm alive!") once the process is
# up, without touching Postgres or a provider (docs.litellm.ai/docs/proxy/health). The
# base image has no curl/wget, so the check goes through the bundled Python instead;
# urlopen raises on a non-2xx response, which is the failure case this check wants.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["python3", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:4000/health/liveliness', timeout=3)"]

CMD ["--config", "/app/config.yaml", "--port", "4000"]
