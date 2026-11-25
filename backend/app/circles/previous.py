"""The bell's «السابقة»: the invitations and requests answered in the last
30 days, to this account and from it."""

from datetime import datetime, timedelta

from flask import Blueprint
from sqlalchemy import func, select
from sqlalchemy.orm import Session, aliased

from app.auth.decorators import require_auth
from app.circles.naming import account_name, name_for
from app.circles.support import answer, care_work
from app.circles.views import iso_time
from app.errors import NotFound
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleRequest,
)


def previous_item(
    kind, row, answered_at, circle_name, person_account, unnamed_phone
) -> dict:
    """One answered invitation or request as «السابقة» lists it."""
    return {
        "id": str(row.id),
        "kind": kind,
        "status": row.status,
        "answered_at": iso_time(answered_at),
        "circle_name": circle_name,
        "other_name": account_name(person_account),
        "other_avatar_code": (
            person_account.avatar_code if person_account else None
        ),
        "other_phone_number": unnamed_phone if person_account is None
        else None,
    }


def previous_invitations(session, account, since, name) -> list[dict]:
    """Invitations to this account and from it, answered since `since`."""
    other, patient = aliased(Account), aliased(Account)
    invitation = CareCircleInvitation
    answered = invitation.status.in_(["accepted", "declined"])
    items = []
    for kind, mine, person in (
        ("invitation_received",
         invitation.invitee_phone_number == account.phone_number,
         invitation.invited_by_account_id),
        ("invitation_sent", invitation.invited_by_account_id == account.id,
         invitation.responded_by_account_id),
    ):
        rows = session.execute(
            select(invitation, CareCircle, other, patient)
            .join(CareCircle, CareCircle.id == invitation.care_circle_id)
            .outerjoin(other, other.id == person)
            .outerjoin(patient, patient.id == CareCircle.account_id)
            .where(mine, answered, invitation.responded_at > since)
        ).all()
        items += [
            previous_item(
                kind, row, row.responded_at, name(circle, patient_account),
                person_account,
                row.invitee_phone_number if kind == "invitation_sent"
                else None,
            )
            for row, circle, person_account, patient_account in rows
        ]
    return items


def previous_requests(session, account, since, name) -> list[dict]:
    """Circle requests about this account and from it, ended since
    `since`."""
    other, patient = aliased(Account), aliased(Account)
    request = CareCircleRequest
    # Superseded: closed when the patient got a circle another way.
    done = request.status.in_(["completed", "declined", "superseded"])
    when = func.coalesce(request.completed_at, request.responded_at)
    items = []
    for kind, mine, person in (
        ("request_received",
         request.patient_phone_number == account.phone_number,
         request.requested_by_account_id),
        ("request_sent", request.requested_by_account_id == account.id,
         request.responded_by_account_id),
    ):
        rows = session.execute(
            select(request, CareCircle, other, patient)
            .outerjoin(CareCircle, CareCircle.id == request.care_circle_id)
            .outerjoin(other, other.id == person)
            .outerjoin(patient, patient.id == CareCircle.account_id)
            .where(mine, done, when > since)
        ).all()
        items += [
            previous_item(
                kind, row, row.completed_at or row.responded_at,
                name(circle, patient_account), person_account,
                row.patient_phone_number if kind == "request_sent" else None,
            )
            for row, circle, person_account, patient_account in rows
        ]
    return items


# How long an answered invitation or request stays in «السابقة».
PREVIOUS_VISIBLE_DAYS = 30


def previous_notifications_view(
    session: Session, account: Account, now: datetime
) -> list[dict]:
    """What was answered in the last 30 days, newest first: invitations to
    this account and from it, and circle requests about it and from it.

    Each item says what it was (`kind`), how it ended (`status`), when
    (`answered_at`), the circle's name as this account reads it, and the
    other person (`other_name` and `other_avatar_code`, or
    `other_phone_number` for someone who has no name here)."""
    since = now - timedelta(days=PREVIOUS_VISIBLE_DAYS)

    def name(circle: CareCircle | None, patient_account) -> str | None:
        if circle is None:
            return None
        return name_for(
            account.id,
            own_name=circle.name,
            patient_account_id=circle.account_id,
            patient_account_name=account_name(patient_account),
            patient_first_name=circle.first_name,
        )

    items = previous_invitations(session, account, since, name)
    items += previous_requests(session, account, since, name)
    return sorted(
        items, key=lambda item: (item["answered_at"], item["id"]),
        reverse=True,
    )


previous_bp = Blueprint(
    "previous_notifications", __name__, url_prefix="/api/v1/notifications"
)


@previous_bp.get("/previous")
@require_auth
def previous():
    """Invitations and circle requests to and from the caller that were
    answered in the last 30 days, newest first."""
    with care_work() as work:
        account = work.session.get(Account, work.actor)
        if account is None:
            raise NotFound("This user does not exist.", code="user_not_found")
        items = previous_notifications_view(
            work.session, account, work.now
        )
    return answer({"previous": items})
