"""Demo data for trying the app against a local server.

    flask --app wsgi demo-data              make the demo data
    flask --app wsgi demo-data --reset      delete it and make it fresh
    flask --app wsgi demo-data --if-missing make it only when it is missing

Removing the demo accounts, whether a demo may be made here, and making it
again are here too."""

from datetime import datetime

import click
from flask import current_app
from flask.cli import with_appcontext
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.care import CareService
from app.database import transaction
from app.demo import DEMO_PHONES
from app.demo_data.builder import DemoBuilder
from app.demo_data.story import DEMO_ZONE, Summary
from app.extensions import get_clock
from app.models import Account, CareCircle, CareCircleManager


def remove_demo_accounts(session: Session, now: datetime) -> int:
    """Delete the demo accounts as the app deletes an account.

    Each one deletes its own circle and the circles it manages alone, and
    leaves any circle that someone else also manages. Accounts that are
    not demo accounts are never touched.

    The circles that only demo accounts manage are deleted first, whole.
    Otherwise, after Lina accepted Sara's invitation on the phone, deleting
    one account first changes the doses it recorded (their recorder becomes
    empty) and deleting the other then removes those doses with the circle.
    The database checks every changed dose when the transaction ends, finds
    its medicine gone, and refuses the whole reset ("Dose date does not
    belong to this schedule").
    """
    # The demo accounts, and the circles they manage.
    accounts = session.scalars(
        select(Account)
        .where(Account.phone_number.in_(DEMO_PHONES))
        .order_by(Account.phone_number)
    ).all()
    demo_ids = {account.id for account in accounts}
    managed = session.scalars(
        select(CareCircle).where(
            CareCircle.id.in_(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id.in_(demo_ids)
                )
            )
        )
    ).all()
    # First the circles that only demo accounts manage, whole (see above).
    for circle in managed:
        managers = set(
            session.scalars(
                select(CareCircleManager.account_id).where(
                    CareCircleManager.care_circle_id == circle.id
                )
            )
        )
        if managers <= demo_ids:
            session.delete(circle)
    session.flush()
    # Then each demo account, as the app deletes an account.
    care = CareService(session, now)
    for account in accounts:
        care.delete_account(
            account.id,
            patient_choice="delete",
            delete_last_managed_circles=True,
        )
    session.flush()
    return len(accounts)


def demo_allowed(config) -> bool:
    """Whether the demo accounts can be made here: never in production,
    and only where no real SMS can reach their made-up numbers."""
    return config["APP_ENV"] != "production" and (
        config.get("SMS_BACKEND") == "fake"
        or config.get("DEMO_SIGN_IN_CODE") is not None
    )


def rebuild_demo(now: datetime, *, reset: bool) -> tuple[bool, Summary]:
    """Make the demo story at `now`; with `reset`, delete it first.

    Returns whether an old one was deleted, and what was made. Raises
    LookupError when it is already there and `reset` is not set.
    """
    now = now.astimezone(DEMO_ZONE)
    with transaction() as session:
        exists = session.scalar(
            select(Account.id).where(Account.phone_number.in_(DEMO_PHONES))
        )
        if exists and not reset:
            raise LookupError("The demo data is already there.")
        removed = remove_demo_accounts(session, now) > 0 if reset else False
        summary = DemoBuilder(session, now).build()
    return removed, summary


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
