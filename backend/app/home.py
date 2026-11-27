"""GET /api/v1/home: the signed-in account's home, without clinical data,
and its circles, each with the name this account reads, what it may edit
there, and the patient."""

from uuid import UUID

from flask import Blueprint, current_app, jsonify
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.cities import city_point
from app.circles.leader import AREAS, access_by_circle
from app.circles.naming import name_for
from app.database import transaction
from app.errors import ServiceUnavailable, Unauthorized
from app.extensions import get_user_store
from app.models import Account, CareCircle, CareCircleManager


def circle_rows(session, account_id: UUID):
    """The circles this account is a member of or receives care in, with
    the patient's account when there is one; each once."""
    memberships = select(CareCircleManager.care_circle_id).where(
        CareCircleManager.account_id == account_id
    )
    receives_care = select(CareCircle.id).where(
        CareCircle.account_id == account_id
    )
    return session.execute(
        select(
            CareCircle.id,
            CareCircle.name,
            CareCircle.avatar_code,
            CareCircle.account_id,
            CareCircle.first_name,
            CareCircle.time_zone,
            Account.display_name,
            Account.first_name.label("account_first_name"),
            Account.avatar_code.label("account_avatar_code"),
        )
        .outerjoin(Account, Account.id == CareCircle.account_id)
        .where(CareCircle.id.in_(memberships.union(receives_care)))
    )


def circle_item(row, account_id: UUID, access: dict) -> dict:
    """One circle as the home screen shows it."""
    areas = access.get(row.id, {area: False for area in AREAS})
    return {
        "id": str(row.id),
        # A patient with their own account picks this circle's name for
        # themself; everyone else sees «دائرة» and the patient's name,
        # never the patient's personal choice (e.g. "صحتي").
        "name": name_for(
            account_id,
            own_name=row.name,
            patient_account_id=row.account_id,
            patient_account_name=row.display_name or row.account_first_name,
            patient_first_name=row.first_name,
        ),
        # Whether this account may add and change medicines, measurements,
        # appointments here (`app.circles.leader`).
        "can_manage_medications": areas["medications"],
        "can_manage_measurements": areas["measurements"],
        "can_manage_appointments": areas["appointments"],
        # Whether this account leads the circle, and whether its patient
        # has an account: a visit nobody goes with reminds the patient, or,
        # for a patient without a phone, the leader («حضرت» too).
        "is_leader": areas.get("leads", False),
        "patient_has_account": row.account_id is not None,
        # Who the app speaks to about this circle: the patient («أخذت
        # الجرعة»), or someone caring for them, who reads the patient's name
        # instead («… أخذ نورة للجرعة»).
        "is_patient": row.account_id == account_id,
        "patient_name": (
            row.display_name or row.account_first_name or row.first_name
        ),
        # A linked patient shares the account's own avatar, like their
        # photo.
        "patient_avatar_code": (
            row.account_avatar_code
            if row.account_id is not None
            else row.avatar_code
        ),
        # The patient's IANA zone: the app shows and schedules every time of
        # this circle in it, wherever the phone is.
        "time_zone": row.time_zone,
    }


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
    # Where the account's own city is, for its weather on «اليوم»; null
    # without a city, or for one typed by hand.
    latitude, longitude = city_point(user.city)
    response = jsonify(
        account={
            "id": user.id,
            "display_name": user.display_name,
            "profile_complete": user.profile_complete,
            "avatar_code": avatar_code,
            "latitude": latitude,
            "longitude": longitude,
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
