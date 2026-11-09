"""The shared test server's demo, made fresh by the external scheduler.

The demo story is built around the moment it is made (a dose due an hour
ago, the next one in 45 minutes), so it ages: a scheduled workflow calls
this each morning, and anyone may run that workflow before showing the
demo (.github/workflows/demo-refresh.yml).
"""

import hmac

from flask import Blueprint, current_app, jsonify, request

from app.errors import NotFound, ServiceUnavailable
from app.extensions import get_clock

bp = Blueprint("demo", __name__, url_prefix="/internal")


@bp.post("/demo-data")
def refresh_demo():
    """Delete the demo accounts and make the demo story again, now.

    Requires the `X-Tick-Secret` header to equal `TICK_SECRET`, and a
    server where the demo may be made (never production, and only with no
    real SMS for the demo numbers); refuses as a plain 404 otherwise.
    """
    from app.demo_data import demo_allowed, rebuild_demo

    config = current_app.config
    secret = config.get("TICK_SECRET")
    if (
        not secret
        or not demo_allowed(config)
        or not hmac.compare_digest(
            request.headers.get("X-Tick-Secret", ""), secret
        )
    ):
        raise NotFound()
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    _, summary = rebuild_demo(get_clock().now(), reset=True)
    return jsonify(circles=summary.circles, medicines=summary.plans)
