"""The external scheduler's entry point: run the scheduled notification
scan once. See README ("Scheduled notifications") for how it is called.
"""

import hmac

from flask import Blueprint, current_app, request

from app.errors import NotFound, ServiceUnavailable
from app.extensions import get_clock
from app.push.scheduled import run_tick

bp = Blueprint("tick", __name__, url_prefix="/internal")


@bp.post("/tick")
def tick():
    """Scan every circle for a due/missed dose or measurement, and every
    appointment due for its day-before reminder.

    Requires the `X-Tick-Secret` header to equal `TICK_SECRET`; refuses as
    a plain 404 otherwise, so an unconfigured or probing caller learns
    nothing about the endpoint.
    """
    secret = current_app.config.get("TICK_SECRET")
    if not secret or not hmac.compare_digest(
        request.headers.get("X-Tick-Secret", ""), secret
    ):
        raise NotFound()
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    run_tick(get_clock().now())
    return "", 204
