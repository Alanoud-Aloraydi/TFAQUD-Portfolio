"""Deleting the rows the scan keeps no longer: old sign-in code requests,
old notification claims, and doses past three months."""

from datetime import datetime, timedelta

from sqlalchemy import delete

from app.database import transaction
from app.medications.retention import doses_kept_from, first_kept_day
from app.models import (
    MedicationDoseRecord,
    MedicationExtraDose,
    NotificationLog,
    OtpRequest,
)

# How long a row that is only needed for a while is kept.
OTP_KEPT = timedelta(days=30)
LOG_KEPT = timedelta(days=14)


def purge_old_rows(now: datetime) -> None:
    """Delete sign-in code requests older than `OTP_KEPT` (their sends go
    with them), log rows older than `LOG_KEPT`, and the doses of the days
    before `first_kept_day`, for good."""
    with transaction() as session:
        session.execute(
            delete(OtpRequest).where(OtpRequest.created_at < now - OTP_KEPT)
        )
        session.execute(
            delete(NotificationLog).where(
                NotificationLog.sent_at < now - LOG_KEPT
            )
        )
        session.execute(
            delete(MedicationDoseRecord).where(
                MedicationDoseRecord.scheduled_on < first_kept_day(now)
            )
        )
        session.execute(
            delete(MedicationExtraDose).where(
                MedicationExtraDose.taken_at < doses_kept_from(now)
            )
        )
