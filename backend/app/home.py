"""Read the signed-in account's home context without clinical data."""

from uuid import UUID

from flask import Blueprint, current_app, jsonify

from app.auth.decorators import current_auth, require_auth
from app.circles.leader import access_by_circle
from app.database import transaction
from app.errors import ServiceUnavailable, Unauthorized
from app.extensions import get_user_store
from app.home_circles import circle_item, circle_rows
from app.models import Account

bp = Blueprint("home", __name__, url_prefix="/api/v1")


@bp.get("/home")
@require_auth
def home():
    """Return account identity and circles accessible through current roles."""
    user = get_user_store().get(current_auth().user_id)
    if user is None:
        raise Unauthorized(code="session_revoked")
    circles = _circles(UUID(user.id)) if user.profile_complete else []
    avatar_code = None
    if "sqlalchemy" in current_app.extensions:
        with transaction() as session:
            account = session.get(Account, UUID(user.id))
            # Read inside the transaction: after it, the row is expired and
            # reading it would open a new transaction that stays open.
            avatar_code = account.avatar_code if account else None
    response = jsonify(
        account={
            "id": user.id,
            "display_name": user.display_name,
            "profile_complete": user.profile_complete,
            "avatar_code": avatar_code,
        },
        care_circles=circles,
    )
    response.headers["Cache-Control"] = "no-store"
    return response


def _circles(account_id: UUID) -> list[dict]:
    """Select authorized IDs without duplicating patient-manager circles,
    in the order of the names this account reads."""
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    with transaction() as session:
        access = access_by_circle(session, account_id)
        circles = [
            circle_item(row, account_id, access)
            for row in circle_rows(session, account_id)
        ]
    return sorted(circles, key=lambda c: (c["name"], c["id"]))
