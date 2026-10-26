"""Turn stored rows into the plain values the API returns.

Ids are returned as text with hyphens, like the circle ids of GET /home.
Times are ISO 8601 with the UTC offset. Phone numbers of other people are
only returned where the screen needs them.
"""

from datetime import datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.authz.roles import CircleRole
from app.models import Account, CareCircle, CareCircleCreationRequest
from app.models import CareCircleManager, CareCircleManagerInvitation
from app.models import EmergencyContact, Patient
from app.medical import MedicalProfile

# How long the sender still sees a declined request in their list.
DECLINED_VISIBLE_DAYS = 7


def _time(value: datetime | None) -> str | None:
    return value.isoformat() if value else None


def patient_view(session: Session, patient: Patient, viewer: UUID) -> dict:
    """Basic data of the patient. Names come from the account while linked."""
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
    }


def circle_view(
    session: Session, circle_id: UUID, viewer: UUID, role: CircleRole
) -> dict:
    """The circle page: patient, members, and (managers only) invitations."""
    circle = session.get(CareCircle, circle_id)
    patient = session.scalar(
        select(Patient).where(Patient.care_circle_id == circle_id)
    )
    members = [
        {
            "display_name": name,
            "is_you": account_id == viewer,
            "role": "manager",
        }
        for account_id, name in sorted(
            session.execute(
                select(CareCircleManager.account_id, Account.display_name)
                .join(Account, Account.id == CareCircleManager.account_id)
                .where(CareCircleManager.care_circle_id == circle_id)
            ).all(),
            # You first, then by name, so the order never jumps around.
            key=lambda row: (row[0] != viewer, row[1] or "", str(row[0])),
        )
    ]
    view = {
        "id": str(circle.id),
        "name": circle.name,
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
    """A request as the person it is about (the future patient) sees it."""
    circle_name = None
    if patient.first_name:
        circle_name = f"{request.proposed_circle_label} {patient.first_name}"
    return {
        "id": str(request.id),
        "status": request.status,
        "circle_label": request.proposed_circle_label,
        "circle_name": circle_name,
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
    rows = session.execute(
        select(invitation, CareCircle.name, Account.display_name)
        .join(CareCircle, CareCircle.id == invitation.care_circle_id)
        .outerjoin(Account, Account.id == invitation.invited_by_account_id)
        .where(
            invitation.invitee_phone_number == account.phone_number,
            invitation.status == "pending",
        )
        .order_by(invitation.created_at.desc(), invitation.id)
    ).all()
    return [
        {
            "id": str(row.id),
            "circle_name": circle_name,
            "invited_by": (
                {"display_name": inviter_name} if inviter_name else None
            ),
            "created_at": _time(row.created_at),
            "last_sent_at": _time(row.last_sent_at),
        }
        for row, circle_name, inviter_name in rows
    ]
