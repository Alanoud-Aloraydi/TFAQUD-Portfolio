"""The push endpoints and commands.

The app sends its phone's OneSignal subscription after signing in, kept
with that sign-in. The external scheduler runs the scan once and reads the
counters (`/internal`), and Render's cron job runs `flask --app wsgi
tick`."""

import hmac
from uuid import UUID

import click
from flask import Blueprint, current_app, jsonify, request
from flask.cli import with_appcontext
from sqlalchemy import update

from app import metrics
from app.auth.decorators import current_auth, require_auth
from app.background import keep_awake
from app.database import transaction
from app.errors import NotFound, ServiceUnavailable
from app.extensions import get_clock
from app.models import AccountSession
from app.push.reminder import reminders_on
from app.push.scheduled import run_tick
from app.validation import Dto, parse_json_body


bp = Blueprint("push", __name__, url_prefix="/api/v1/accounts/me")


class PushSubscriptionInput(Dto):
    """The body of PUT /accounts/me/push-subscription: the id of the phone's
    OneSignal push subscription, and whether the app leaves the reminders
    at its tasks' times to the server (an app from before says nothing)."""

    subscription_id: UUID
    server_reminders: bool = False


@bp.put("/push-subscription")
@require_auth
def keep_push_subscription():
    """Keep this phone's subscription for the caller's sign-in, in place of
    the one it sent before; taken from any other sign-in that had it. Answer
    whether the server sends this phone the reminders at the tasks' times."""
    body = parse_json_body(PushSubscriptionInput)
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    this = UUID(current_auth().session_id)
    # Only while the server sends them (SERVER_REMINDERS and OneSignal set
    # up); otherwise the app goes on setting its own.
    granted = body.server_reminders and reminders_on()
    with transaction() as session:
        session.execute(
            update(AccountSession)
            .where(
                AccountSession.push_subscription_id == body.subscription_id,
                AccountSession.id != this,
            )
            .values(push_subscription_id=None)
        )
        session.execute(
            update(AccountSession)
            .where(AccountSession.id == this)
            .values(
                push_subscription_id=body.subscription_id,
                server_reminders=granted,
            )
        )
    return jsonify(server_reminders=granted)


tick_bp = Blueprint("tick", __name__, url_prefix="/internal")


def _require_tick_secret() -> None:
    """A plain 404 unless `X-Tick-Secret` equals `TICK_SECRET`, so an
    unconfigured or probing caller learns nothing about the endpoint."""
    secret = current_app.config.get("TICK_SECRET")
    if not secret or not hmac.compare_digest(
        request.headers.get("X-Tick-Secret", ""), secret
    ):
        raise NotFound()


@tick_bp.post("/tick")
def tick():
    """Scan every circle for a dose or measurement that was missed (the
    reminders before them, and before appointments, are set on the phone).

    Requires the `X-Tick-Secret` header to equal `TICK_SECRET`.
    """
    _require_tick_secret()
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    run_tick(get_clock().now())
    return "", 204


@tick_bp.get("/metrics")
def read_metrics():
    """This process's counters since it started (`metrics.snapshot`).

    Requires the `X-Tick-Secret` header, like the scan.
    """
    _require_tick_secret()
    response = jsonify(metrics.snapshot())
    response.headers["Cache-Control"] = "no-store"
    return response


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
