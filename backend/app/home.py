"""Read the signed-in account's home context without clinical data."""

from uuid import UUID

from flask import Blueprint, current_app, jsonify
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.circles.naming import name_for
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
                Patient.first_name,
                Patient.time_zone,
                Account.display_name,
                Account.first_name.label("account_first_name"),
                Account.avatar_code.label("account_avatar_code"),
            )
            .join(Patient, Patient.care_circle_id == CareCircle.id)
            .outerjoin(Account, Account.id == Patient.account_id)
            .where(CareCircle.id.in_(manages.union(receives_care)))
        )
        circles = [
            {
                "id": str(row.id),
                # A patient with their own account picks this circle's name
                # for themself; everyone else sees «دائرة» and the patient's
                # name, never the patient's personal choice (e.g. "صحتي").
                "name": name_for(
                    account_id,
                    own_name=row.name,
                    patient_account_id=row.account_id,
                    patient_account_name=(
                        row.display_name or row.account_first_name
                    ),
                    patient_first_name=row.first_name,
                ),
                "can_manage_medications": row.id in managed_ids,
                # Who the app speaks to about this circle: the patient
                # («أخذت الجرعة»), or someone caring for them, who reads
                # the patient's name instead («… أخذ نورة للجرعة»).
                "is_patient": row.account_id == account_id,
                "patient_name": (
                    row.display_name
                    or row.account_first_name
                    or row.first_name
                ),
                # A linked patient shares the account's own avatar, like
                # their photo.
                "patient_avatar_code": (
                    row.account_avatar_code
                    if row.account_id is not None
                    else row.avatar_code
                ),
                # The patient's IANA zone: the app shows and schedules
                # every time of this circle in it, wherever the phone is.
                "time_zone": row.time_zone,
            }
            for row in session.execute(statement)
        ]
        # In the order of the names this account reads.
        return sorted(circles, key=lambda c: (c["name"], c["id"]))
