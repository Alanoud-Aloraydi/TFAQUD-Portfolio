"""The demo: its accounts' numbers and names, shared by the demo story
(app.demo_data) and the sign-in of those numbers (app.sms), and the
endpoint the shared test server's scheduler calls to make it fresh.

The numbers are made up (+96650000000x), so no real SMS may ever reach
them: they sign in with the demo code."""

import hmac
from datetime import date

from flask import Blueprint, current_app, jsonify, request

from app.errors import NotFound, ServiceUnavailable
from app.extensions import get_clock


# Phone, first name, last name, display name, and the birth date and city
# that onboarding asks for.
#   - Lina manages her own care, her mother's and her uncle's: the
#     detailed mode.
#   - Sara manages her grandfather's care and helps with Lina's uncle.
#   - Khaled is Lina's uncle, the patient of his own circle: the
#     simplified mode.
DEMO_ACCOUNTS = (
    ("+966500000001", "لينا", "العتيبي", "لينا", date(1994, 3, 12), "الرياض"),
    ("+966500000002", "سارة", "القحطاني", "سارة", date(1990, 9, 2), "جدة"),
    ("+966500000004", "خالد", "العتيبي", "خالد", date(1952, 6, 1), "الرياض"),
)

DEMO_PHONES = tuple(phone for phone, *_ in DEMO_ACCOUNTS)

# The story's other made-up number, which Lina asks for a circle
# (app/demo_data/story.py). It signs in with the demo code as well, so the
# request can be answered on a phone, and no SMS can reach a stranger.
REQUEST_DEMO_PHONE = "+966500000003"

# Every made-up number that signs in with the demo code.
SIGN_IN_DEMO_PHONES = (*DEMO_PHONES, REQUEST_DEMO_PHONE)

bp = Blueprint("demo", __name__, url_prefix="/internal")


@bp.post("/demo-data")
def refresh_demo():
    """Delete the demo accounts and make the demo story again, now.

    Requires the `X-Tick-Secret` header to equal `TICK_SECRET`, and a
    server where the demo may be made (never production, and only with no
    real SMS for the demo numbers); refuses as a plain 404 otherwise.
    """
    from app.demo_data import demo_allowed, rebuild_demo

    # Like the tick: a plain 404 without the secret, and only where the demo is
    # allowed.
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
    # Delete the demo and build it again, for today's dates.
    _, summary = rebuild_demo(get_clock().now(), reset=True)
    return jsonify(circles=summary.circles, medicines=summary.plans)
