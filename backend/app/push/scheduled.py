"""The scheduled tick: a dose or measurement that was missed, each told
once to the circle and logged so a repeat tick never resends it.

The reminders before a dose, a measurement or an appointment (at its time,
and for an appointment a day before and two hours before) are set on each
phone by the app itself, so they come on time without this tick and without
the server. The server tells only what a phone cannot know ahead: that a
task's time passed and nothing was recorded, and that a task someone else
put off came again (app/snoozes/due.py; this tick catches what its timer
missed). A task put off is not called missed while it waits.

Called by `/internal/tick` on an external schedule (see README). Never
raises: a failed scan or send is logged and the tick moves on, so one bad
circle never blocks the rest. Each tick also deletes the rows kept only for
a while: sign-in code requests after 30 days (they hold a phone number,
a device id and an IP address), and its own log after 14 days.
"""

import logging
from datetime import date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app import metrics
from app.clock import local_moment, patient_today, patient_zone
from app.database import transaction
from app.medications.queries import MedicationQueries
from app.measurements.queries import MeasurementQueries
from app.models import (
    CareCircle,
    CareCircleManager,
    NotificationLog,
    OtpRequest,
)
from app.push.notify import Push, notify
from app.push.sender import PushMessage
from app.snoozes.due import send_due_snoozes
from app.snoozes.queries import put_off_until

log = logging.getLogger(__name__)

# How long a row that is only needed for a while is kept.
OTP_KEPT = timedelta(days=30)
LOG_KEPT = timedelta(days=14)


def run_tick(now: datetime) -> None:
    """Remind of the tasks put off whose time came, delete the rows past
    their time, then scan every circle once; swallow one circle's error."""
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
            _scan_doses(circle_id, now)
            _scan_measurements(circle_id, now)
        except Exception:  # noqa: BLE001 - one circle must not stop the rest
            log.warning(
                "Scheduled scan failed for a circle.", exc_info=True
            )


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


def _claim(
    kind: str, target_id: str, scheduled_on: str, time_of_day: str | None
) -> bool:
    """True the first time this notification is claimed; False on a
    repeat."""
    try:
        with transaction() as session:
            session.add(NotificationLog(
                kind=kind,
                target_id=UUID(target_id),
                scheduled_on=date.fromisoformat(scheduled_on),
                time_of_day=(
                    time.fromisoformat(time_of_day) if time_of_day else None
                ),
            ))
    except IntegrityError:
        return False
    return True


def _circle_recipients(
    session: Session, patient: CareCircle
) -> tuple[UUID, ...]:
    """Every manager of the patient's circle, plus the patient if they have
    an account."""
    recipients = set(
        session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id == patient.id
            )
        )
    )
    if patient.account_id is not None:
        recipients.add(patient.account_id)
    return tuple(recipients)


def _key(task_id: str, occurrence: dict) -> tuple:
    """An occurrence's key in `put_off_until`."""
    return (
        task_id,
        occurrence["scheduled_on"],
        occurrence["time_of_day"][:5],
    )


def _patient(session: Session, circle_id: UUID) -> CareCircle | None:
    """The circle's patient; None when the circle went since the scan
    began."""
    return session.scalar(
        select(CareCircle).where(CareCircle.id == circle_id)
    )


def _scan_doses(circle_id: UUID, now: datetime) -> None:
    """Send «جرعة ما تسجّلت» once for each of the circle's doses of the
    patient's today whose time passed with nothing recorded.
    """
    # Today's doses and who to tell, read in one short transaction; the pushes
    # go after it.
    with transaction() as session:
        patient = _patient(session, circle_id)
        if patient is None:
            return
        today = patient_today(patient, now)
        occurrences = MedicationQueries(session, now).occurrences(
            circle_id, today, today
        )
        moved = put_off_until(session, circle_id, "dose", today)
        recipients = _circle_recipients(session, patient)
    for occurrence in occurrences:
        if (
            occurrence["record"] is not None
            or occurrence["timing_state"] != "missed"
        ):
            continue
        # A dose put off («ذكّرني لاحقًا») is missed only once its grace has
        # passed after its new time.
        until = moved.get(_key(occurrence["schedule_id"], occurrence))
        if until is not None and now <= until + timedelta(
            minutes=occurrence["missed_after_minutes"]
        ):
            continue
        # `_claim` logs the dose once; a scan that finds it logged sent it
        # already.
        if not _claim(
            "dose_missed",
            occurrence["schedule_id"],
            occurrence["scheduled_on"],
            None,
        ):
            continue
        metrics.increment("tick.missed_dose")
        # «ما تسجّلت» says only what the app knows: the dose may have been
        # taken and not recorded.
        notify(
            Push(
                recipients,
                PushMessage(
                    "جرعة ما تسجّلت",
                    f"جرعة {occurrence['name']} ما تسجّلت للحين. "
                    "تقدر تسجّلها من تفقّد.",
                    "dose_missed",
                ),
            )
        )


def _scan_measurements(circle_id: UUID, now: datetime) -> None:
    """Send «قياس ما تسجّل» once for each of the circle's reading times of
    the patient's today that passed with nothing recorded.
    """
    # Today's reading times and who to tell, read in one short transaction.
    with transaction() as session:
        patient = _patient(session, circle_id)
        if patient is None:
            return
        today = patient_today(patient, now)
        occurrences = MeasurementQueries(session, now).occurrences(
            circle_id, today, today
        )
        moved = put_off_until(session, circle_id, "measurement", today)
        zone = patient_zone(patient)
        recipients = _circle_recipients(session, patient)
    for occurrence in occurrences:
        if occurrence["status"] != "missed":
            continue
        # The same for a reading time put off: its grace again after its new
        # time (the grace is the time from the task to its deadline).
        until = moved.get(_key(occurrence["version_id"], occurrence))
        if until is not None:
            grace = datetime.fromisoformat(
                occurrence["deadline_at"]
            ) - local_moment(
                date.fromisoformat(occurrence["scheduled_on"]),
                time.fromisoformat(occurrence["time_of_day"]),
                zone,
            )
            if now <= until + grace:
                continue
        kind_name = "سكر الدم" if occurrence["kind"] == "glucose" else (
            "ضغط الدم"
        )
        # One alert per reading time of the day.
        if not _claim(
            "measurement_missed",
            occurrence["plan_version_id"],
            occurrence["scheduled_on"],
            occurrence["time_of_day"],
        ):
            continue
        metrics.increment("tick.missed_measurement")
        notify(
            Push(
                recipients,
                PushMessage(
                    "قياس ما تسجّل",
                    f"قياس {kind_name} ما تسجّل للحين. "
                    "تقدر تسجّله من تفقّد.",
                    "measurement_missed",
                ),
            )
        )
