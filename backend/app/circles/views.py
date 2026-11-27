"""Turn stored rows into the plain values the API returns.

Ids are text with hyphens, like the circle ids of GET /home. Times are ISO
8601 with the UTC offset. This module is the circle page: the patient, the
members, and (managers only) the invitations, which the invited person
reads too."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session, aliased

from app.authz import CircleRole
from app.circles.leader import AREAS, edit_access, leader_id, patient_leads
from app.circles.naming import account_name, name_for
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleManager,
)


def iso_time(value: datetime | None) -> str | None:
    """A time as ISO 8601 text, or None."""
    return value.isoformat() if value else None


def patient_view(session: Session, patient: CareCircle, viewer: UUID) -> dict:
    """Basic data of the patient. Names and avatar come from the account
    while linked: one person, one picture, like their photo."""
    # A patient with an account shows the account's names and picture; one
    # without shows the circle's.
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        "birth_date": source.birth_date.isoformat(),
        "city": source.city,
        # Every time of the circle is wall clock in this IANA zone.
        "time_zone": patient.time_zone,
        "has_account": linked is not None,
        "app_mode": linked.app_mode if linked else None,
        "is_you": linked is not None and linked.id == viewer,
        "avatar_code": source.avatar_code,
    }


def member_view(
    membership, name, avatar_code, phone_number, *, viewer, leader,
    patient_account,
) -> dict:
    """One member as the circle page shows them."""
    account_id = membership.account_id
    access = edit_access(membership, account_id == leader)
    edits = any(access.values())
    return {
        "account_id": str(account_id),
        "display_name": name,
        "is_you": account_id == viewer,
        "is_patient": account_id == patient_account,
        # The one who removes members and says who edits what.
        "is_leader": account_id == leader,
        "role": "manager" if edits else "member",
        # Each area this member may edit; `can_edit` (any of them) for
        # the app before the areas.
        "edit_access": access,
        "can_edit": edits,
        # Already the account's own avatar; a patient who manages their
        # own circle shares it, like their photo.
        "avatar_code": avatar_code,
        # So any circle member can call another, the same as an
        # emergency contact's number.
        "phone_number": phone_number,
    }


def circle_members(
    session, circle_id, viewer, leader, patient_account
) -> list:
    """The circle's members: the patient, you, the leader, then by name."""
    rows = session.execute(
        select(CareCircleManager, Account.display_name,
               Account.avatar_code, Account.phone_number)
        .join(Account, Account.id == CareCircleManager.account_id)
        .where(CareCircleManager.care_circle_id == circle_id)
    ).all()
    rows.sort(key=lambda row: (row[0].account_id != patient_account,
                               row[0].account_id != viewer,
                               row[0].account_id != leader, row[1] or "",
                               str(row[0].account_id)))
    return [
        member_view(
            *row, viewer=viewer, leader=leader,
            patient_account=patient_account,
        )
        for row in rows
    ]


def patient_member(patient, linked, viewer) -> dict:
    """The patient with an account who is not a member, shown first."""
    patient_account = patient.account_id
    patient_name = (
        f"{linked.first_name} {linked.last_name}" if linked
        else f"{patient.first_name} {patient.last_name}"
    )
    return {
        "account_id": str(patient_account) if patient_account else None,
        "display_name": patient_name.strip(),
        "is_you": patient_account == viewer,
        "is_patient": True,
        "is_leader": False,
        "role": "patient",
        "edit_access": {area: False for area in AREAS},
        "can_edit": False,
        "avatar_code": linked.avatar_code if linked else patient.avatar_code,
        "phone_number": linked.phone_number if linked else None,
    }


def invitation_view(invitation: CareCircleInvitation) -> dict:
    """An invitation as the managers of the circle see it."""
    return {
        "id": str(invitation.id),
        "invitee_phone_number": invitation.invitee_phone_number,
        "status": invitation.status,
        "created_at": iso_time(invitation.created_at),
        "last_sent_at": iso_time(invitation.last_sent_at),
    }


def received_invitations_view(
    session: Session, account: Account
) -> list[dict]:
    """Pending invitations addressed to this account's phone number."""
    invitation = CareCircleInvitation
    inviter = aliased(Account)
    patient_account = aliased(Account)
    rows = session.execute(
        select(
            invitation,
            CareCircle.name,
            inviter.display_name,
            inviter.avatar_code,
            CareCircle.account_id,
            CareCircle.first_name,
            patient_account.display_name.label("patient_display_name"),
            patient_account.first_name.label("patient_account_first_name"),
        )
        .join(CareCircle, CareCircle.id == invitation.care_circle_id)
        .outerjoin(inviter, inviter.id == invitation.invited_by_account_id)
        .outerjoin(
            patient_account, patient_account.id == CareCircle.account_id
        )
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
            "circle_name": name_for(
                account.id,
                own_name=row.name,
                patient_account_id=row.account_id,
                patient_account_name=(
                    row.patient_display_name or row.patient_account_first_name
                ),
                patient_first_name=row.first_name,
            ),
            "invited_by": (
                {
                    "display_name": row.display_name,
                    "avatar_code": row.avatar_code,
                }
                if row.display_name
                else None
            ),
            "created_at": iso_time(row[0].created_at),
            "last_sent_at": iso_time(row[0].last_sent_at),
        }
        for row in rows
    ]


def pending_invitations(session, circle_id) -> list[dict]:
    """The circle's pending invitations, newest first."""
    return [
        invitation_view(invitation)
        for invitation in session.scalars(
            select(CareCircleInvitation)
            .where(
                CareCircleInvitation.care_circle_id == circle_id,
                CareCircleInvitation.status == "pending",
            )
            .order_by(
                CareCircleInvitation.created_at.desc(),
                CareCircleInvitation.id,
            )
        )
    ]


def circle_view(
    session: Session, circle_id: UUID, viewer: UUID, role: CircleRole
) -> dict:
    """The circle page: patient, members, and (managers only) invitations."""
    circle = patient = session.get(CareCircle, circle_id)
    # `is_patient` marks the manager who is also the patient, so the app
    # can show who the file belongs to.
    patient_account = patient.account_id if patient is not None else None
    leader = leader_id(session, circle)
    members = circle_members(
        session, circle_id, viewer, leader, patient_account
    )
    linked_patient = (
        session.get(Account, patient_account) if patient_account else None
    )
    if patient_account is not None and not any(
        member["is_patient"] for member in members
    ):
        members.insert(0, patient_member(patient, linked_patient, viewer))
    view = {
        "id": str(circle.id),
        # The patient sees their own name for it; the others «دائرة» and
        # the patient's name (`app.circles.naming`).
        "name": name_for(
            viewer,
            own_name=circle.name,
            patient_account_id=patient_account,
            patient_account_name=account_name(linked_patient),
            patient_first_name=patient.first_name,
        ),
        "role": role.value,
        "patient": patient_view(session, patient, viewer),
        "members": members,
        # The leader («قائد الدائرة», `app.circles.leader`): only they
        # remove members and say who edits what, and they may hand the
        # circle to another member unless the patient leads it.
        "leader_account_id": str(leader) if leader else None,
        "can_manage_members": leader == viewer,
        "can_hand_over": leader == viewer and not patient_leads(
            session, circle
        ),
        # What the viewer may edit here.
        "your_edit_access": next(
            (m["edit_access"] for m in members if m["is_you"]),
            {area: False for area in AREAS},
        ),
    }
    if role == CircleRole.MANAGER:
        view["pending_invitations"] = pending_invitations(session, circle_id)
    return view
