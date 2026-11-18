"""`flask --app wsgi keep-only NUMBER...`: only these accounts stay.

Without --yes it only says what would be deleted. Never in production.
"""

import click
from flask import current_app
from flask.cli import with_appcontext

from app.config.phone_values import saudi_mobile
from app.database import transaction
from app.extensions import get_clock
from app.keep_only.plan import keep_plan
from app.keep_only.report import plan_lines
from app.keep_only.run import apply_keep_plan


@click.command("keep-only")
@click.argument("numbers", nargs=-1, required=True)
@click.option(
    "--yes",
    is_flag=True,
    help="Delete. Without it, nothing is deleted: only what would be.",
)
@with_appcontext
def keep_only_command(numbers: tuple[str, ...], yes: bool) -> None:
    """Keep only the accounts of NUMBERS (5XXXXXXXX or +9665XXXXXXXX,
    spaces or commas between them); delete every other account, every
    circle that has one of them, and what waits for their numbers."""
    if current_app.config["APP_ENV"] == "production":
        raise click.ClickException("keep-only never runs in production.")
    keep = _numbers(numbers)
    with transaction() as session:
        plan = keep_plan(session, keep)
        for line in plan_lines(plan):
            click.echo(line)
        if not plan.kept:
            # Most likely the wrong database, or the numbers mistyped.
            raise click.ClickException(
                "None of these numbers has an account here: nothing is "
                "deleted."
            )
        if not yes:
            click.echo("Nothing was deleted. Run it again with --yes.")
            return
        apply_keep_plan(session, plan, get_clock().now())
    click.echo(
        f"Done: {len(plan.accounts)} accounts and {len(plan.circles)} "
        "circles deleted."
    )


def _numbers(numbers: tuple[str, ...]) -> set[str]:
    """Every number given, as +9665XXXXXXXX; a wrong one stops it all."""
    keep: set[str] = set()
    for given in numbers:
        for part in given.split(","):
            if not part.strip():
                continue
            phone = saudi_mobile(part)
            if phone is None:
                raise click.BadParameter(
                    f"{part.strip()!r} is not a Saudi mobile number."
                )
            keep.add(phone)
    return keep
