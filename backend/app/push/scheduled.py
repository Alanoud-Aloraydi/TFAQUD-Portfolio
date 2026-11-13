"""The scheduled tick: a dose, a measurement or an appointment that was
missed, each told once to the circle and logged so a repeat tick never
resends it. Each person is called by name (app/push/missed_texts.py).

The reminders before a dose, a measurement or an appointment (at its time,
and for an appointment a day before and two hours before) are set on each
phone by the app itself, so they come on time without this tick and without
the server. The server tells only what a phone cannot know ahead: that a
task's time passed and nothing was recorded, that an appointment passed two
hours ago and nobody marked it visited or cancelled, and that a task someone
else put off came again (app/snoozes/due.py; this tick catches what its
timer missed). A task put off is not called missed while it waits.

Called by `/internal/tick` on an external schedule (see README). Never
raises: a failed scan or send is logged and the tick moves on, so one bad
circle never blocks the rest. Each tick also deletes the rows kept only for
a while: sign-in code requests after 30 days (they hold a phone number,
a device id and an IP address), and its own log after 14 days.
"""

import logging
from collections.abc import Callable
from dataclasses import dataclass
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
    Account,
    CareCircle,
    CareCircleManager,
    NotificationLog,
    OtpRequest,
)
from app.models.appointment import Appointment
from app.push.missed_texts import (
    APPOINTMENT_TITLE,
    DOSE_TITLE,
    MEASUREMENT_TITLE,
    appointment_missed_text,
    dose_missed_text,
    measurement_missed_text,
)
from app.push.notify import Push, notify
from app.push.sender import PushMessage
from app.snoozes.due import send_due_snoozes
from app.snoozes.queries import put_off_until

log = logging.getLogger(__name__)

# How long a row that is only needed for a while is kept.
OTP_KEPT = timedelta(days=30)
LOG_KEPT = timedelta(days=14)

# An appointment nobody marked visited or cancelled is called missed this
# long after its time; past `APPOINTMENT_TOO_LATE` after that it is no
# longer told (a tick that was down for long sends no stale news).
APPOINTMENT_MISSED_AFTER = timedelta(hours=2)
APPOINTMENT_TOO_LATE = timedelta(hours=12)


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
            _scan_appointments(circle_id, now)
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


@dataclass(frozen=True)
class _Audience:
    """Who hears of one circle's missed tasks: every manager, plus the
    patient if they have an account, each with the name they are called
    by; and the patient's account and name, which the others hear."""

    names: dict[UUID, str | None]
    patient_account_id: UUID | None
    patient_name: str | None


def _audience(session: Session, patient: CareCircle) -> _Audience:
    """Read the circle's audience in the open transaction."""
    recipients = set(
        session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id == patient.id
            )
        )
    )
    if patient.account_id is not None:
        recipients.add(patient.account_id)
    # Each account's display name, else its first name, in one read.
    rows = session.execute(
        select(Account.id, Account.display_name, Account.first_name).where(
            Account.id.in_(recipients)
        )
    ) if recipients else ()
    known = {row.id: row.display_name or row.first_name for row in rows}
    return _Audience(
        names={account_id: known.get(account_id) for account_id in recipients},
        patient_account_id=patient.account_id,
        patient_name=known.get(patient.account_id) or patient.first_name,
    )


def _tell(
    audience: _Audience,
    title: str,
    kind: str,
    text: Callable[[str | None, bool], str],
) -> None:
    """Send each person of `audience` their own message: `text(name, own)`,
    where `own` is true for the patient."""
    for account_id, name in audience.names.items():
        own = account_id == audience.patient_account_id
        notify(Push((account_id,), PushMessage(title, text(name, own), kind)))


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
    """Send «جرعة فائتة» once for each of the circle's doses of the
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
        audience = _audience(session, patient)
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
        # The dose's time passed with nothing recorded: it is missed
        # («فائتة»), and it can still be taken and recorded.
        medicine = occurrence["name"]
        _tell(
            audience,
            DOSE_TITLE,
            "dose_missed",
            lambda name, own, medicine=medicine: dose_missed_text(
                medicine, name=name, own=own, patient=audience.patient_name
            ),
        )


def _scan_measurements(circle_id: UUID, now: datetime) -> None:
    """Send «قياس فائت» once for each of the circle's reading times of
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
        audience = _audience(session, patient)
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
        # One alert per reading time of the day.
        if not _claim(
            "measurement_missed",
            occurrence["plan_version_id"],
            occurrence["scheduled_on"],
            occurrence["time_of_day"],
        ):
            continue
        metrics.increment("tick.missed_measurement")
        reading = occurrence["kind"]
        _tell(
            audience,
            MEASUREMENT_TITLE,
            "measurement_missed",
            lambda name, own, reading=reading: measurement_missed_text(
                reading, name=name, own=own, patient=audience.patient_name
            ),
        )


def _scan_appointments(circle_id: UUID, now: datetime) -> None:
    """Send «موعد فائت» once for each of the circle's appointments whose
    time passed `APPOINTMENT_MISSED_AFTER` ago and that nobody marked
    done («تم الموعد») or cancelled.
    """
    with transaction() as session:
        patient = _patient(session, circle_id)
        if patient is None:
            return
        zone = patient_zone(patient)
        today = patient_today(patient, now)
        # Yesterday's too: one late at night is missed after midnight.
        appointments = [
            (item.id, item.scheduled_on, item.time_of_day)
            for item in session.scalars(
                select(Appointment).where(
                    Appointment.care_circle_id == circle_id,
                    Appointment.status == "scheduled",
                    Appointment.scheduled_on.between(
                        today - timedelta(days=1), today
                    ),
                )
            )
        ]
        audience = _audience(session, patient)
    for appointment_id, day, wall_time in appointments:
        missed_at = (
            local_moment(day, wall_time, zone) + APPOINTMENT_MISSED_AFTER
        )
        if not missed_at <= now < missed_at + APPOINTMENT_TOO_LATE:
            continue
        if not _claim(
            "appointment_missed", str(appointment_id), day.isoformat(), None
        ):
            continue
        metrics.increment("tick.missed_appointment")
        _tell(
            audience,
            APPOINTMENT_TITLE,
            "appointment_missed",
            lambda name, own: appointment_missed_text(
                name=name, own=own, patient=audience.patient_name
            ),
        )
