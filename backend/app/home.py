"""Read the signed-in account's home context without clinical data."""

from uuid import UUID

from flask import Blueprint, current_app, jsonify
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.database import transaction
from app.errors import ServiceUnavailable, Unauthorized
from app.extensions import get_user_store
from app.models import CareCircle, CareCircleManager, Patient

bp = Blueprint("home", __name__, url_prefix="/api/v1")


@bp.get("/home")
@require_auth
def home():
    """Return account identity and circles accessible through current roles."""
    user = get_user_store().get(current_auth().user_id)
    if user is None:
        raise Unauthorized(code="session_revoked")
    circles = _circles(UUID(user.id)) if user.profile_complete else []
    response = jsonify(
        account={
            "id": user.id,
            "display_name": user.display_name,
            "profile_complete": user.profile_complete,
        },
        care_circles=circles,
    )
    response.headers["Cache-Control"] = "no-store"
    return response


def _circles(account_id: UUID) -> list[dict]:
    """Select authorized IDs without duplicating patient-manager circles."""
    if "sqlalchemy" not in current_app.extensions:
        raise ServiceUnavailable()
    manages = select(CareCircleManager.care_circle_id).where(
        CareCircleManager.account_id == account_id
    )
    receives_care = select(Patient.care_circle_id).where(
        Patient.account_id == account_id
    )
    statement = (
        select(CareCircle.id, CareCircle.name)
        .where(CareCircle.id.in_(manages.union(receives_care)))
        .order_by(CareCircle.name, CareCircle.id)
    )
    with transaction() as session:
        return [
            {"id": str(row.id), "name": row.name}
            for row in session.execute(statement)
        ]
