"""`flask demo-data`: the demo story in the local database."""

import click
from flask import current_app
from flask.cli import with_appcontext

from app.demo_data.lifecycle import demo_allowed, rebuild_demo
from app.extensions import get_clock


@click.command("demo-data")
@click.option(
    "--reset",
    is_flag=True,
    help="Delete the demo accounts and their circles first.",
)
@click.option(
    "--if-missing",
    is_flag=True,
    help="Do nothing when the demo data is already there.",
)
@with_appcontext
def demo_data_command(reset: bool, if_missing: bool) -> None:
    """Fill the local database with demo circles, medicines and doses."""
    config = current_app.config
    if config["APP_ENV"] == "production":
        raise click.ClickException("Demo data is never made in production.")
    if not demo_allowed(config):
        if if_missing:
            # The server's start (DEMO_DATA=true) must not stop because real
            # SMS was switched on: it only leaves the demo data out.
            click.echo(
                "The demo data is skipped: real SMS is on, the demo numbers "
                "are made up, and DEMO_SIGN_IN_CODE is not set."
            )
            return
        raise click.ClickException(
            "The demo numbers are made up, so they must not get a real SMS. "
            "Set SMS_BACKEND=fake, or DEMO_SIGN_IN_CODE, restart the server, "
            "and run this again."
        )
    try:
        removed, summary = rebuild_demo(get_clock().now(), reset=reset)
    except LookupError:
        if if_missing:
            click.echo("The demo data is already there.")
            return
        raise click.ClickException(
            "The demo data is already there. Run with --reset to make it "
            "fresh."
        ) from None
    if removed:
        click.echo("The old demo data was deleted.")
    click.echo("Demo data is ready.")
    click.echo(f"  Circles: {', '.join(summary.circles)}")
    click.echo(
        f"  Medicines: {summary.plans} ({summary.revisions} changes)"
    )
    click.echo(
        f"  Doses: {summary.taken} taken, {summary.skipped} skipped, "
        f"{summary.open_doses} due now, the rest missed or to come"
    )
    click.echo(
        "Sign in on the phone with 0500000001 (detailed mode) or "
        "0500000004 (simplified mode). The code is DEMO_SIGN_IN_CODE when "
        "it is set, else in the server log (FAKE SMS ... Your code is ...)."
    )
