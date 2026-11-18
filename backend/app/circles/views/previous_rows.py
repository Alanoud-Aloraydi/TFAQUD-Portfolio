"""The invitations and requests answered lately, read for «السابقة»."""

from sqlalchemy import func, select
from sqlalchemy.orm import aliased

from app.circles import naming
from app.circles.views.times import iso_time
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
        "other_name": naming.account_name(person_account),
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
