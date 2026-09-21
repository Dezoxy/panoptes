"""The `panoptes` command-line interface.

This module wires up the top-level `panoptes` Typer app and its sub-apps. Every
sub-app command is a placeholder today: the platform is still at the scaffolding
stage (see the repository README service catalogue), and each placeholder exits
non-zero so a caller cannot mistake it for working automation.
"""

from __future__ import annotations

from typing import Annotated

import typer

from panoptes_platform import __version__

app = typer.Typer(
    name="panoptes",
    help="Platform operations for the shared AI platform.",
    no_args_is_help=True,
)

onboard_app = typer.Typer(
    help="Risk-based onboarding lifecycle, from discovery through to retirement.",
    no_args_is_help=True,
)
budget_app = typer.Typer(
    help="Telemetry and cost attribution, with budgets per consumer.",
    no_args_is_help=True,
)
evidence_app = typer.Typer(
    help="Policy as code and control evidence collection.",
    no_args_is_help=True,
)
copilot_app = typer.Typer(
    help="Copilot estate administration.",
    no_args_is_help=True,
)


def _not_implemented() -> None:
    """Report that the enclosing sub-command has no implementation yet."""
    typer.echo("not implemented")
    raise typer.Exit(code=2)


@onboard_app.command("status")
def onboard_status() -> None:
    """Report onboarding lifecycle status. Not implemented yet."""
    _not_implemented()


@budget_app.command("status")
def budget_status() -> None:
    """Report budget and cost attribution status. Not implemented yet."""
    _not_implemented()


@evidence_app.command("status")
def evidence_status() -> None:
    """Report policy and evidence collection status. Not implemented yet."""
    _not_implemented()


@copilot_app.command("status")
def copilot_status() -> None:
    """Report Copilot estate administration status. Not implemented yet."""
    _not_implemented()


app.add_typer(onboard_app, name="onboard")
app.add_typer(budget_app, name="budget")
app.add_typer(evidence_app, name="evidence")
app.add_typer(copilot_app, name="copilot")


def _version_callback(show_version: bool) -> None:
    if show_version:
        typer.echo(__version__)
        raise typer.Exit()


@app.callback()
def main(
    version: Annotated[
        bool,
        typer.Option(
            "--version",
            help="Show the panoptes-platform version and exit.",
            callback=_version_callback,
            is_eager=True,
        ),
    ] = False,
) -> None:
    """Platform operations for the shared AI platform."""


if __name__ == "__main__":
    app()
