"""The external scheduler's entry points: run the scheduled notification
scan once, and read the counters to alert on. See README ("Scheduled
notifications" and "Deadlines, breakers and counters").
"""

import hmac

from flask import Blueprint, current_app, jsonify, request

from app import metrics
from app.errors import NotFound, ServiceUnavailable
from app.extensions import get_clock
from app.push.scheduled import run_tick

bp = Blueprint("tick", __name__, url_prefix="/internal")


def _require_tick_secret() -> None:
    """A plain 404 unless `X-Tick-Secret` equals `TICK_SECRET`, so an
    unconfigured or probing caller learns nothing about the endpoint."""
    secret = current_app.config.get("TICK_SECRET")
    if not secret or not hmac.compare_digest(
        request.headers.get("X-Tick-Secret", ""), secret
    ):
        raise NotFound()


@bp.post("/tick")
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


@bp.get("/metrics")
def read_metrics():
    """This process's counters since it started (`metrics.snapshot`).

    Requires the `X-Tick-Secret` header, like the scan.
    """
    _require_tick_secret()
    response = jsonify(metrics.snapshot())
    response.headers["Cache-Control"] = "no-store"
    return response
