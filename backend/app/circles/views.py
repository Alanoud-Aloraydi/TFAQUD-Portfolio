"""Turn stored rows into the plain values the API returns.

Ids are returned as text with hyphens, like the circle ids of GET /home.
Times are ISO 8601 with the UTC offset. Phone numbers of other people are
only returned where the screen needs them.
"""

from datetime import datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session, aliased

from app.authz.roles import CircleRole
from app.circles import naming
from app.models import Account, CareCircle, CareCircleCreationRequest
from app.models import CareCircleManager, CareCircleManagerInvitation
from app.models import EmergencyContact, Patient
from app.medical import MedicalProfile

# How long the sender still sees a declined request in their list.
DECLINED_VISIBLE_DAYS = 7


def _time(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def patient_view(session: Session, patient: Patient, viewer: UUID) -> dict:
    """Basic data of the patient. Names and avatar come from the account
    while linked: one person, one picture, like their photo."""
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        "birth_date": patient.birth_date.isoformat(),
        "city": patient.city,
        "latitude": patient.latitude,
        "longitude": patient.longitude,
        "has_account": linked is not None,
        "app_mode": linked.app_mode if linked else None,
        "is_you": linked is not None and linked.id == viewer,
        "avatar_code": source.avatar_code,
    }


def circle_view(
    session: Session, circle_id: UUID, viewer: UUID, role: CircleRole
) -> dict:
    """The circle page: patient, members, and (managers only) invitations."""
    circle = session.get(CareCircle, circle_id)
    patient = session.scalar(
        select(Patient).where(Patient.care_circle_id == circle_id)
    )
    # `is_patient` marks the manager who is also the patient, so the app
    # can show who the file belongs to.
    patient_account = patient.account_id if patient is not None else None
    members = [
        {
            "account_id": str(account_id),
            "display_name": name,
            "is_you": account_id == viewer,
            "is_patient": account_id == patient_account,
            "role": "manager",
            # Already the account's own avatar; a patient who manages their
            # own circle shares it, like their photo.
            "avatar_code": avatar_code,
        }
        for account_id, name, avatar_code in sorted(
            session.execute(
                select(CareCircleManager.account_id, Account.display_name,
                       Account.avatar_code)
                .join(Account, Account.id == CareCircleManager.account_id)
                .where(CareCircleManager.care_circle_id == circle_id)
            ).all(),
            key=lambda row: (row[0] != patient_account,
                             row[0] != viewer, row[1] or "", str(row[0])),
        )
    ]
    if patient_account is not None and not any(
        member["is_patient"] for member in members
    ):
        linked = (
            session.get(Account, patient_account)
            if patient_account else None
        )
        patient_name = (
            f"{linked.first_name} {linked.last_name}" if linked
            else f"{patient.first_name} {patient.last_name}"
        )
        members.insert(0, {
            "account_id": str(patient_account) if patient_account else None,
            "display_name": patient_name.strip(),
            "is_you": patient_account == viewer,
            "is_patient": True,
            "role": "patient",
            "avatar_code": linked.avatar_code if linked else patient.avatar_code,
        })
    linked_patient = (
        session.get(Account, patient_account) if patient_account else None
    )
    view = {
        "id": str(circle.id),
        # The patient sees their own name for it; the others «دائرة» and
        # the patient's name (`app.circles.naming`).
        "name": naming.name_for(
            viewer,
            own_name=circle.name,
            patient_account_id=patient_account,
            patient_account_name=naming.account_name(linked_patient),
            patient_first_name=patient.first_name if patient else None,
        ),
        "role": role.value,
        "patient": patient_view(session, patient, viewer),
        "members": members,
    }
    if role == CircleRole.MANAGER:
        view["pending_invitations"] = [
            invitation_view(invitation)
            for invitation in session.scalars(
                select(CareCircleManagerInvitation)
                .where(
                    CareCircleManagerInvitation.care_circle_id == circle_id,
                    CareCircleManagerInvitation.status == "pending",
                )
                .order_by(
                    CareCircleManagerInvitation.created_at.desc(),
                    CareCircleManagerInvitation.id,
                )
            )
        ]
    return view


def invitation_view(invitation: CareCircleManagerInvitation) -> dict:
    """An invitation as the managers of the circle see it."""
    return {
        "id": str(invitation.id),
        "invitee_phone_number": invitation.invitee_phone_number,
        "status": invitation.status,
        "created_at": _time(invitation.created_at),
        "last_sent_at": _time(invitation.last_sent_at),
    }


def contact_view(contact: EmergencyContact) -> dict:
    return {
        "id": str(contact.id),
        "name": contact.name,
        "relation": contact.relation,
        "phone_number": contact.phone_number,
    }


def medical_view(profile: MedicalProfile) -> dict:
    return {
        "blood_type": profile.blood_type,
        "conditions": profile.conditions,
        "allergies": profile.allergies,
    }


def emergency_card_view(
    session: Session,
    patient: Patient,
    profile: MedicalProfile,
    contacts: list[EmergencyContact],
) -> dict:
    """The emergency card: only what a helper needs to read quickly.

    The card is shown to people who help in an emergency, so it carries no
    birth date, city or coordinates. Names come from the account while the
    patient is linked to one, like in `patient_view`.
    """
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        **medical_view(profile),
        "emergency_contacts": [contact_view(c) for c in contacts],
    }


# ---- creation requests --------------------------------------------------


def sent_request_view(request: CareCircleCreationRequest) -> dict:
    """A request as the person who sent it sees it."""
    return {
        "id": str(request.id),
        "patient_phone_number": request.patient_phone_number,
        "circle_label": request.proposed_circle_label,
        "proposed_app_mode": request.proposed_app_mode,
        "status": request.status,
        "created_at": _time(request.created_at),
        "responded_at": _time(request.responded_at),
        "care_circle_id": (
            str(request.care_circle_id) if request.care_circle_id else None
        ),
    }


def received_request_view(
    request: CareCircleCreationRequest, requester: Account, patient: Account
) -> dict:
    """A request as the person it is about (the future patient) sees it.

    The patient names the circle themself when they complete the request,
    so there is no circle name yet (`circle_name` is null). `circle_label`
    is kept for older apps.
    """
    return {
        "id": str(request.id),
        "status": request.status,
        "circle_label": request.proposed_circle_label,
        "circle_name": None,
        "proposed_app_mode": request.proposed_app_mode,
        "requested_by": {
            "display_name": requester.display_name,
            "first_name": requester.first_name,
            "last_name": requester.last_name,
        },
        "created_at": _time(request.created_at),
    }


def creation_requests_view(
    session: Session, account: Account, now: datetime
) -> dict:
    """Requests the account sent, and requests that name its phone number."""
    request = CareCircleCreationRequest
    recent = now - timedelta(days=DECLINED_VISIBLE_DAYS)
    sent = session.scalars(
        select(request)
        .where(
            request.requested_by_account_id == account.id,
            or_(
                request.status.in_(["pending", "accepted"]),
                and_(
                    request.status == "declined", request.responded_at > recent
                ),
            ),
        )
        .order_by(request.created_at.desc(), request.id)
    ).all()
    received = session.execute(
        select(request, Account)
        .join(Account, Account.id == request.requested_by_account_id)
        .where(
            request.patient_phone_number == account.phone_number,
            request.status.in_(["pending", "accepted"]),
        )
        .order_by(request.created_at.desc(), request.id)
    ).all()
    return {
        "sent": [sent_request_view(row) for row in sent],
        "received": [
            received_request_view(row, requester, account)
            for row, requester in received
        ],
    }


# ---- received invitations --------------------------------------------


def received_invitations_view(
    session: Session, account: Account
) -> list[dict]:
    """Pending invitations addressed to this account's phone number."""
    invitation = CareCircleManagerInvitation
    inviter = aliased(Account)
    patient_account = aliased(Account)
    rows = session.execute(
        select(
            invitation,
            CareCircle.name,
            inviter.display_name,
            Patient.account_id,
            Patient.first_name,
            patient_account.display_name.label("patient_display_name"),
            patient_account.first_name.label("patient_account_first_name"),
        )
        .join(CareCircle, CareCircle.id == invitation.care_circle_id)
        .join(Patient, Patient.care_circle_id == CareCircle.id)
        .outerjoin(inviter, inviter.id == invitation.invited_by_account_id)
        .outerjoin(patient_account, patient_account.id == Patient.account_id)
        .where(
            invitation.invitee_phone_number == account.phone_number,
            invitation.status == "pending",
        )
        .order_by(invitation.created_at.desc(), invitation.id)
    ).all()
    return [
        {
            "id": str(row[0].id),
            # As the invited person will see it: «دائرة» and the patient's
            # name, never the patient's own choice.
            "circle_name": naming.name_for(
                account.id,
                own_name=row.name,
                patient_account_id=row.account_id,
                patient_account_name=(
                    row.patient_display_name or row.patient_account_first_name
                ),
                patient_first_name=row.first_name,
            ),
            "invited_by": (
                {"display_name": row.display_name} if row.display_name else None
            ),
            "created_at": _time(row[0].created_at),
            "last_sent_at": _time(row[0].last_sent_at),
        }
        for row in rows
    ]
