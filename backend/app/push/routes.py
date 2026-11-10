"""The app sends its phone's Apple push token after the person signs in.

The token is kept with the sign-in (session) that sent it: after a sign-out
that phone gets nothing more, and the row goes with the session. A sign-in
keeps one token, the last one its app sent: an app sends its token every
time it opens, and iOS can give the phone a new one. The old token is then
deleted, so Apple's later "no longer active" for it cannot end a sign-in
whose app is still there (notify.py).
"""

from typing import Annotated
from uuid import UUID

from flask import Blueprint, current_app
from pydantic import StringConstraints
from sqlalchemy import delete
from sqlalchemy.dialects.postgresql import insert

from app.auth.decorators import current_auth, require_auth
from app.database import transaction
from app.errors import ServiceUnavailable
from app.extensions import get_clock
from app.models import PushDevice
from app.validation import Dto, parse_json_body

bp = Blueprint("push", __name__, url_prefix="/api/v1/accounts/me")

# Apple's device token, written as hexadecimal (64 characters today).
PushToken = Annotated[
    str, StringConstraints(pattern=r"^[0-9a-fA-F]{64,200}$")
]


class PushDeviceInput(Dto):
    """The body of PUT /accounts/me/push-device: the phone's Apple push token.
    """

    token: PushToken


@bp.put("/push-device")
@require_auth
def register_push_device():
    """Keep this phone's token for the caller's sign-in, in place of the one
    it sent before. A token that was another sign-in's (the phone changed
    hands) moves to this one."""
    body = parse_json_body(PushDeviceInput)
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    # The token belongs to this sign-in: a token seen before moves to it (a
    # phone that signed in again).
    auth = current_auth()
    now = get_clock().now()
    values = {
        "account_id": UUID(auth.user_id),
        "session_id": UUID(auth.session_id),
        "updated_at": now,
    }
    token = body.token.lower()
    with transaction() as session:
        # The token this sign-in sent before, if iOS has given a new one.
        session.execute(
            delete(PushDevice).where(
                PushDevice.session_id == values["session_id"],
                PushDevice.token != token,
            )
        )
        statement = insert(PushDevice).values(
            token=token, created_at=now, **values
        )
        session.execute(
            statement.on_conflict_do_update(
                index_elements=[PushDevice.token], set_=values
            )
        )
    return "", 204
