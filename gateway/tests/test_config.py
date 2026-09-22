"""Tests for `gateway/config.yaml` (ADR-0003: the gateway route table is config as code).

These tests parse the file with PyYAML and check the invariants the platform relies on:
every route carries the classification metadata the risk-tiering rubric needs, no
credential is inlined, every fallback chain resolves, the Restricted-only group never
falls back to a vendor outside the firm's tenancy, and the two logging/auth controls
ADR-0003 requires are actually on.

The config is loaded once at import time rather than through pytest fixtures: it is
read-only, shared by every test, and this keeps the module free of the `pytest` typing
dependency the repository's pre-commit `mypy` hook does not install (see
`additional_dependencies` in `.pre-commit-config.yaml`, which lists only `typer`).
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any

import yaml

CONFIG_PATH = Path(__file__).resolve().parent.parent / "config.yaml"
CONFIG_TEXT = CONFIG_PATH.read_text(encoding="utf-8")

_loaded: Any = yaml.safe_load(CONFIG_TEXT)
assert isinstance(_loaded, dict)
CONFIG: dict[str, Any] = _loaded

MODEL_LIST: list[dict[str, Any]] = CONFIG["model_list"]
assert isinstance(MODEL_LIST, list) and MODEL_LIST

VALID_DATA_CLASSES = {"Public", "Internal", "Confidential", "Restricted"}
VALID_TIERS = {1, 2, 3}
VALID_RESIDENCIES = {"eu-sweden-central", "eu-data-zone", "vendor-us", "own-tenancy", "broker"}
RESTRICTED_RESIDENCIES = {"eu-sweden-central", "own-tenancy"}

# A `sk-` prefixed token, a `key=`/`key:` assignment followed by a plausible secret
# value, or a run of 32+ contiguous hex characters (long enough to be a raw key or
# token, short enough that a dashed UUID such as a tenant or client id never matches).
SECRET_LOOKALIKE_PATTERNS = (
    re.compile(r"sk-[A-Za-z0-9_-]{8,}"),
    re.compile(r"""key\s*[=:]\s*['"]?[A-Za-z0-9_-]{8,}"""),
    re.compile(r"\b[0-9a-fA-F]{32,}\b"),
)


def test_every_model_has_required_model_info_fields() -> None:
    for entry in MODEL_LIST:
        name = entry["model_name"]
        info = entry.get("model_info")
        assert info is not None, f"{name}: missing model_info"

        for field in ("provider", "data_class_max", "tier_max", "residency"):
            assert field in info, f"{name}: model_info missing '{field}'"

        assert isinstance(info["provider"], str) and info["provider"], f"{name}: empty provider"
        assert info["data_class_max"] in VALID_DATA_CLASSES, (
            f"{name}: invalid data_class_max {info['data_class_max']!r}"
        )
        assert info["tier_max"] in VALID_TIERS, f"{name}: invalid tier_max {info['tier_max']!r}"
        assert info["residency"] in VALID_RESIDENCIES, (
            f"{name}: invalid residency {info['residency']!r}"
        )


def test_no_secret_lookalikes_in_config() -> None:
    for pattern in SECRET_LOOKALIKE_PATTERNS:
        match = pattern.search(CONFIG_TEXT)
        assert match is None, f"possible secret in gateway/config.yaml: {match.group(0)!r}"


def test_fallback_chain_models_all_exist() -> None:
    known_names = {entry["model_name"] for entry in MODEL_LIST}
    fallbacks = CONFIG["router_settings"]["fallbacks"]
    assert fallbacks, "router_settings.fallbacks is empty"

    for chain in fallbacks:
        assert isinstance(chain, dict) and len(chain) == 1
        ((source, targets),) = chain.items()
        assert source in known_names, f"fallback source {source!r} is not a model_list entry"
        for target in targets:
            assert target in known_names, f"fallback target {target!r} is not a model_list entry"


def test_chat_restricted_only_falls_back_within_the_tenancy() -> None:
    fallbacks = CONFIG["router_settings"]["fallbacks"]
    chat_restricted_chain = next(iter(d for d in fallbacks if "chat-restricted" in d))
    group_members = {"chat-restricted", *chat_restricted_chain["chat-restricted"]}

    residencies = {
        entry["model_info"]["residency"]
        for entry in MODEL_LIST
        if entry["model_name"] in group_members
    }
    assert residencies, "no model_list entries found for the chat-restricted group"
    stray = residencies - RESTRICTED_RESIDENCIES
    assert not stray, f"chat-restricted group reaches a non-restricted residency: {stray}"


def test_message_logging_is_off_by_default() -> None:
    assert CONFIG["litellm_settings"]["turn_off_message_logging"] is True


def test_jwt_auth_is_enabled() -> None:
    assert CONFIG["general_settings"]["enable_jwt_auth"] is True


def test_every_api_key_is_an_environment_reference() -> None:
    checked = 0
    for entry in MODEL_LIST:
        api_key = entry["litellm_params"].get("api_key")
        if api_key is None:
            continue
        checked += 1
        assert api_key.startswith("os.environ/"), (
            f"{entry['model_name']}: api_key is not an os.environ/ reference: {api_key!r}"
        )
    assert checked > 0, "no model_list entry declared an api_key to check"
