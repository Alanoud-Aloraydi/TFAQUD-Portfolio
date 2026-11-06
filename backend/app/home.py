"""Read the signed-in account's home context without clinical data."""

from uuid import UUID

from flask import Blueprint, current_app, jsonify
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.database import transaction
from app.errors import ServiceUnavailable, Unauthorized
from app.extensions import get_user_store
from app.models import Account, CareCircle, CareCircleManager, Patient

bp = Blueprint("home", __name__, url_prefix="/api/v1")


@bp.get("/home")
@require_auth
def home():
    """Return account identity and circles accessible through current roles."""
    user = get_user_store().get(current_auth().user_id)
    if user is None:
        raise Unauthorized(code="session_revoked")
    circles = _circles(UUID(user.id)) if user.profile_complete else []
    account = None
    if "sqlalchemy" in current_app.extensions:
        with transaction() as session:
            account = session.get(Account, UUID(user.id))
    response = jsonify(
        account={
            "id": user.id,
            "display_name": user.display_name,
            "profile_complete": user.profile_complete,
            "avatar_code": account.avatar_code if account else None,
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
    with transaction() as session:
        managed_ids = set(session.scalars(manages))
        statement = (
            select(
                CareCircle.id,
                CareCircle.name,
                Patient.avatar_code,
                Patient.account_id,
                Account.display_name,
                Account.avatar_code.label("account_avatar_code"),
            )
            .join(Patient, Patient.care_circle_id == CareCircle.id)
            .outerjoin(Account, Account.id == Patient.account_id)
            .where(CareCircle.id.in_(manages.union(receives_care)))
            .order_by(CareCircle.name, CareCircle.id)
        )
        return [
            {
                "id": str(row.id),
                # A patient with their own account picks this circle's name
                # for themself; everyone else sees it named after them,
                # not the patient's personal choice (e.g. "صحتي").
                "name": (
                    f"دائرة {row.display_name}"
                    if row.account_id is not None
                    and row.account_id != account_id
                    else row.name
                ),
                "can_manage_medications": row.id in managed_ids,
                # A linked patient shares the account's own avatar, like
                # their photo.
                "patient_avatar_code": (
                    row.account_avatar_code
                    if row.account_id is not None
                    else row.avatar_code
                ),
            }
            for row in session.execute(statement)
        ]
