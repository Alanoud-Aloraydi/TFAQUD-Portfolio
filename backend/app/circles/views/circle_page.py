"""The circle page: patient, members, and (managers only) invitations."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.authz.roles import CircleRole
from app.circles import naming
from app.circles.leader import AREAS, leader_id, patient_leads
from app.circles.views.invitations import invitation_view
from app.circles.views.members import circle_members, patient_member
from app.circles.views.patient import patient_view
from app.models import Account, CareCircle, CareCircleInvitation


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
        "name": naming.name_for(
            viewer,
            own_name=circle.name,
            patient_account_id=patient_account,
            patient_account_name=naming.account_name(linked_patient),
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
