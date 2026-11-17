"""Who leads a care circle («قائد الدائرة»), and what each member may edit.

There is one leader at a time, in this order:

1. the patient, while they use the detailed mode;
2. otherwise the account the circle names (`leader_account_id`): whoever
   made the circle, or whoever the leader handed it to;
3. and when that account is no longer a member, the member who joined
   first.

The leader removes members and lets each one edit the medicines, the
measurements and the appointments, or not. The leader always edits all
three. Recording a dose or a reading, putting a task off, and the visit
sheet are not edits: every member who edits anything may do them.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle, CareCircleManager

AREAS = ("medications", "measurements", "appointments")


def patient_leads(session: Session, circle: CareCircle) -> bool:
    """Whether the circle's patient leads it: they have an account in the
    detailed mode."""
    if circle.account_id is None:
        return False
    mode = session.scalar(
        select(Account.app_mode).where(Account.id == circle.account_id)
    )
    return mode == "detailed"


def leader_id(session: Session, circle: CareCircle) -> UUID | None:
    """The account that leads `circle` now; None for a circle with nobody
    to lead it."""
    if patient_leads(session, circle):
        return circle.account_id
    members = session.scalars(
        select(CareCircleManager.account_id)
        .where(CareCircleManager.care_circle_id == circle.id)
        .order_by(CareCircleManager.created_at, CareCircleManager.account_id)
    ).all()
    if circle.leader_account_id in members:
        return circle.leader_account_id
    return members[0] if members else None


def edit_access(membership: CareCircleManager, leads: bool) -> dict:
    """What one member may edit, as the API shows it: the leader all."""
    return {
        area: leads or membership.may_edit(area) for area in AREAS
    }


def access_by_circle(session, account_id: UUID) -> dict:
    """What this account may edit in each circle it is a member of: the
    leader everything (and `leads`), the others what the leader allows."""
    access = {}
    for membership in session.scalars(
        select(CareCircleManager).where(
            CareCircleManager.account_id == account_id
        )
    ):
        circle = session.get(CareCircle, membership.care_circle_id)
        leads = leader_id(session, circle) == account_id
        access[membership.care_circle_id] = {
            **edit_access(membership, leads), "leads": leads,
        }
    return access
