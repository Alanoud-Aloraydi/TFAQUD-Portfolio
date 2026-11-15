"""The bell's «السابقة»: what was answered in the last 30 days."""

from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.circles import naming
from app.circles.views.previous_rows import (
    previous_invitations,
    previous_requests,
)
from app.models import Account, CareCircle

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
        return naming.name_for(
            account.id,
            own_name=circle.name,
            patient_account_id=circle.account_id,
            patient_account_name=naming.account_name(patient_account),
            patient_first_name=circle.first_name,
        )

    items = previous_invitations(session, account, since, name)
    items += previous_requests(session, account, since, name)
    return sorted(
        items, key=lambda item: (item["answered_at"], item["id"]),
        reverse=True,
    )
