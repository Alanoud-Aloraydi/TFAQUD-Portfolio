"""The scheduled scan: `run_tick` sends the reminders whose time came and
tells the circle once of each missed task, and deletes the rows nothing
reads any more (`purge_old_rows`)."""

import logging
from datetime import datetime, timedelta

from sqlalchemy import delete, func, select

from app.database import transaction
from app.medications.doses import doses_kept_from, first_kept_day
from app.models import (
    AccountSession,
    CareCircle,
    CareCircleInvitation,
    CareCircleRequest,
    MedicationDoseRecord,
    MedicationExtraDose,
    NotificationLog,
    OtpRequest,
    TaskSnooze,
)
from app.push.missed import scan_appointments, scan_doses, scan_measurements
from app.push.reminders import scan_reminders
from app.snoozes.due import send_due_snoozes


log = logging.getLogger(__name__)

# How long a row that is only needed for a while is kept.
OTP_KEPT = timedelta(days=30)
LOG_KEPT = timedelta(days=14)
# A session signed out answers like one that never was: nothing reads it.
SIGNED_OUT_KEPT = timedelta(days=30)
# A snooze is read until its reminder went, and the scan reads today's.
SNOOZE_KEPT = timedelta(days=2)
# «السابقة» shows 30 days; a declined, cancelled or superseded invitation
# or request is then read by nothing. An accepted invitation and a
# completed request stay: they say who joined, and that the patient agreed.
DEAD_END_KEPT = timedelta(days=30)


def purge_old_rows(now: datetime) -> None:
    """Delete, for good, what nothing reads any more: sign-in code requests
    older than `OTP_KEPT` (their sends go with them), notification claims
    older than `LOG_KEPT`, sessions signed out `SIGNED_OUT_KEPT` ago, snoozes
    past `SNOOZE_KEPT`, invitations and requests that led nowhere, and the
    doses of the days before `first_kept_day`."""
    invitation, request = CareCircleInvitation, CareCircleRequest
    old = now - DEAD_END_KEPT
    with transaction() as session:
        for statement in (
            delete(OtpRequest).where(OtpRequest.created_at < now - OTP_KEPT),
            delete(NotificationLog).where(
                NotificationLog.sent_at < now - LOG_KEPT
            ),
            delete(AccountSession).where(
                AccountSession.revoked_at < now - SIGNED_OUT_KEPT
            ),
            delete(TaskSnooze).where(
                TaskSnooze.remind_at < now - SNOOZE_KEPT,
                TaskSnooze.scheduled_on < (now - SNOOZE_KEPT).date(),
            ),
            delete(invitation).where(
                invitation.status.in_(["declined", "cancelled"]),
                func.coalesce(invitation.responded_at,
                              invitation.last_sent_at) < old,
            ),
            delete(request).where(
                request.status.in_(["declined", "cancelled", "superseded"]),
                func.coalesce(request.responded_at, request.created_at) < old,
            ),
            delete(MedicationDoseRecord).where(
                MedicationDoseRecord.scheduled_on < first_kept_day(now)
            ),
            delete(MedicationExtraDose).where(
                MedicationExtraDose.taken_at < doses_kept_from(now)
            ),
        ):
            session.execute(statement)


def run_tick(now: datetime, ahead: timedelta = timedelta(0)) -> None:
    """Remind of the tasks put off whose time came, delete the rows past
    their time, then scan every circle once: its reminders whose time came
    (with a timer for each moment in the next `ahead`), then its missed
    tasks. Swallow one circle's error."""
    try:
        send_due_snoozes(now)
    except Exception:  # noqa: BLE001 - the scan must still run
        log.warning("Tasks put off were not reminded.", exc_info=True)
    try:
        purge_old_rows(now)
    except Exception:  # noqa: BLE001 - the scan must still run
        log.warning("Purging old rows failed.", exc_info=True)
    with transaction() as session:
        circle_ids = list(session.scalars(select(CareCircle.id)))
    for circle_id in circle_ids:
        try:
            scan_reminders(circle_id, now, ahead)
        except Exception:  # noqa: BLE001 - the missed tasks must still go
            log.warning("Reminders failed for a circle.", exc_info=True)
        try:
            scan_doses(circle_id, now)
            scan_measurements(circle_id, now)
            scan_appointments(circle_id, now)
        except Exception:  # noqa: BLE001 - one circle must not stop the rest
            log.warning(
                "Scheduled scan failed for a circle.", exc_info=True
            )
