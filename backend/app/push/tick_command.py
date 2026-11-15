"""`flask --app wsgi tick`: the scheduled notification scan, run once.

Render's cron job (render.yaml, every 10 minutes) starts this in its own
short-lived process. It first asks the API's health check, which keeps
the free API from sleeping (app/keep_awake.py). Every push of the scan is
sent before the command ends: a job left waiting would end with the
process.
"""

import click
from flask import current_app
from flask.cli import with_appcontext

from app.extensions import get_clock
from app.keep_awake import keep_awake
from app.push.scheduled import run_tick


@click.command("tick")
@with_appcontext
def tick_command() -> None:
    """Tell of the doses, measurements and appointments missed since the
    last scan, and of the tasks put off that are due."""
    if "sqlalchemy" not in current_app.extensions:
        raise click.ClickException("The scan needs the database.")
    keep_awake(current_app.config.get("KEEP_AWAKE_URL"))
    # The pushes go out in this process, before it ends.
    current_app.config["BACKGROUND_INLINE"] = True
    run_tick(get_clock().now())
    click.echo("Scan done.")
