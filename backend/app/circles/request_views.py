"""Circle requests as the API answers them: as the sender sees them, and
as the patient does."""

from datetime import datetime, timedelta

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.circles.views import iso_time
from app.models import Account, CareCircleRequest


# How long the sender still sees a declined request in their list.
DECLINED_VISIBLE_DAYS = 7


def sent_request_view(request: CareCircleRequest) -> dict:
    """A request as the person who sent it sees it."""
    return {
        "id": str(request.id),
        "patient_phone_number": request.patient_phone_number,
        "proposed_app_mode": request.proposed_app_mode,
        "status": request.status,
        "created_at": iso_time(request.created_at),
        "responded_at": iso_time(request.responded_at),
        "care_circle_id": (
            str(request.care_circle_id) if request.care_circle_id else None
        ),
    }


def received_request_view(
    request: CareCircleRequest, requester: Account
) -> dict:
    """A request as the person it is about (the future patient) sees it.

    The patient names the circle themself when they complete the request,
    so there is no circle name yet (`circle_name` is null).
    """
    return {
        "id": str(request.id),
        "status": request.status,
        "circle_name": None,
        "proposed_app_mode": request.proposed_app_mode,
        "requested_by": {
            "display_name": requester.display_name,
            "first_name": requester.first_name,
            "last_name": requester.last_name,
            "avatar_code": requester.avatar_code,
        },
        "created_at": iso_time(request.created_at),
    }


def creation_requests_view(
    session: Session, account: Account, now: datetime
) -> dict:
    """Requests the account sent, and requests that name its phone number."""
    request = CareCircleRequest
    recent = now - timedelta(days=DECLINED_VISIBLE_DAYS)
    # Sent: the open ones, and the declined ones for a few days so the sender
    # sees the answer.
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
    # Received: the open ones naming this account's number, with who sent each.
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
            received_request_view(row, requester)
            for row, requester in received
        ],
    }
