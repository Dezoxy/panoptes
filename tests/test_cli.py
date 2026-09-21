"""Tests for the `panoptes` CLI entry point."""

from __future__ import annotations

from typer.testing import CliRunner

from panoptes_platform import __version__
from panoptes_platform.cli import app

runner = CliRunner()


def test_version_prints_version() -> None:
    result = runner.invoke(app, ["--version"])
    assert result.exit_code == 0
    assert __version__ in result.stdout


def test_help_lists_sub_apps() -> None:
    result = runner.invoke(app, ["--help"])
    assert result.exit_code == 0
    for sub_app in ("onboard", "budget", "evidence", "copilot"):
        assert sub_app in result.stdout


def test_onboard_status_exits_not_implemented() -> None:
    result = runner.invoke(app, ["onboard", "status"])
    assert result.exit_code == 2
    assert "not implemented" in result.stdout
