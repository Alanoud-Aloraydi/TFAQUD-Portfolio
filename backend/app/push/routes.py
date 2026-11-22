"""The app sends its phone's OneSignal subscription after signing in.

The subscription is kept with the sign-in (session) that sent it, so the
server knows which sign-in each phone is. When OneSignal later reports that
phone's app deleted, that sign-in ends, as a sign-out would (notify.py).
The app sends it every time it opens and when OneSignal gives the phone a
new one. A subscription that was another sign-in's (the phone signed in
again) moves to this one, so one phone is one sign-in.

With it, the app asks for the reminders at its tasks' times from the server
(`server_reminders`). The answer says whether the server sends them to this
phone; only then does the app stop setting its own.
"""

from uuid import UUID

from flask import Blueprint, current_app, jsonify
from sqlalchemy import update

from app.auth.decorators import current_auth, require_auth
from app.database import transaction
from app.errors import ServiceUnavailable
from app.models import AccountSession
from app.push.scheduled.reminders import reminders_on
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
