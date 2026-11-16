"""Deleting the rows the scan keeps no longer: old sign-in code requests
and old notification claims."""

from datetime import datetime, timedelta

from sqlalchemy import delete

from app.database import transaction
from app.models import NotificationLog, OtpRequest

# How long a row that is only needed for a while is kept.
OTP_KEPT = timedelta(days=30)
LOG_KEPT = timedelta(days=14)


def purge_old_rows(now: datetime) -> None:
    """Delete sign-in code requests older than `OTP_KEPT` (their sends go
    with them) and log rows older than `LOG_KEPT`."""
    with transaction() as session:
        session.execute(
            delete(OtpRequest).where(OtpRequest.created_at < now - OTP_KEPT)
        )
        session.execute(
            delete(NotificationLog).where(
                NotificationLog.sent_at < now - LOG_KEPT
            )
        )
