"""The circles of the home screen, as GET /home lists them: each with the
name this account reads, what it may edit there, and the patient."""

from uuid import UUID

from sqlalchemy import select

from app.circles.leader import AREAS, edit_access, leader_id
from app.circles.naming import name_for
from app.models import Account, CareCircle, CareCircleManager


def edit_access_by_circle(session, account_id: UUID) -> dict:
    """What this account may edit in each circle it is a member of: the
    leader everything, the others what the leader allows."""
    access = {}
    for membership in session.scalars(
        select(CareCircleManager).where(
            CareCircleManager.account_id == account_id
        )
    ):
        circle = session.get(CareCircle, membership.care_circle_id)
        access[membership.care_circle_id] = edit_access(
            membership, leader_id(session, circle) == account_id
        )
    return access


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
            CareCircle.latitude,
            CareCircle.longitude,
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
        # Where the patient's city is, for its weather on «اليوم» (the
        # phone's own location is never asked for); null when the city was
        # typed and not picked from the list.
        "latitude": row.latitude,
        "longitude": row.longitude,
    }
