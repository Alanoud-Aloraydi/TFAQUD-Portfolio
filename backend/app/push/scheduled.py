"""The scheduled tick: dose/measurement due or missed, and appointment
reminders, each sent once to the right people and logged so a repeat tick
never resends it.

Called by `/internal/tick` on an external schedule (see README). Never
raises: a failed scan or send is logged and the tick moves on, so one bad
circle never blocks the rest.
"""

import logging
from datetime import datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import transaction
from app.medications.queries import MedicationQueries
from app.measurements.queries import MeasurementQueries
from app.models import (
    Appointment,
    AppointmentCompanion,
    CareCircle,
    CareCircleManager,
    NotificationLog,
    Patient,
)
from app.push.notify import Push, notify
from app.push.sender import PushMessage

log = logging.getLogger(__name__)
RIYADH = ZoneInfo("Asia/Riyadh")


def run_tick(now: datetime) -> None:
    """Scan every circle and appointment once; swallow one circle's error."""
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
    try:
        _scan_appointments(now)
    except Exception:  # noqa: BLE001 - see the module docstring
        log.warning("Scheduled appointment scan failed.", exc_info=True)


def _claim(dedupe_key: str) -> bool:
    """True the first time `dedupe_key` is claimed; False on a repeat."""
    try:
        with transaction() as session:
            session.add(NotificationLog(dedupe_key=dedupe_key))
    except IntegrityError:
        return False
    return True


def _circle_recipients(session: Session, circle_id: UUID) -> tuple[UUID, ...]:
    """Every manager of the circle, plus its patient if they have one."""
    recipients = set(
        session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id == circle_id
            )
        )
    )
    patient = session.scalar(
        select(Patient).where(Patient.care_circle_id == circle_id)
    )
    if patient is not None and patient.account_id is not None:
        recipients.add(patient.account_id)
    return tuple(recipients)


def _scan_doses(circle_id: UUID, now: datetime) -> None:
    today = now.astimezone(RIYADH).date()
    with transaction() as session:
        occurrences = MedicationQueries(session, now).occurrences(
            circle_id, today, today
        )
        recipients = _circle_recipients(session, circle_id)
    for occurrence in occurrences:
        state = occurrence["timing_state"]
        if occurrence["record"] is not None or state not in (
            "due",
            "missed",
        ):
            continue
        key = (
            f"dose_{state}:{occurrence['schedule_id']}:"
            f"{occurrence['scheduled_on']}"
        )
        if not _claim(key):
            continue
        title = (
            "دواء مستحق" if state == "due" else "دواء فات وقته"
        )
        body = (
            f"حان وقت {occurrence['name']}."
            if state == "due"
            else f"فات وقت {occurrence['name']} ولم يُسجَّل."
        )
        notify(Push(recipients, PushMessage(title, body, f"dose_{state}")))


def _scan_measurements(circle_id: UUID, now: datetime) -> None:
    today = now.astimezone(RIYADH).date()
    with transaction() as session:
        occurrences = MeasurementQueries(session, now).occurrences(
            circle_id, today, today
        )
        recipients = _circle_recipients(session, circle_id)
    for occurrence in occurrences:
        status = occurrence["status"]
        if status not in ("due", "missed"):
            continue
        kind_name = "سكر الدم" if occurrence["kind"] == "glucose" else (
            "ضغط الدم"
        )
        key = (
            f"measurement_{status}:{occurrence['version_id']}:"
            f"{occurrence['scheduled_on']}"
        )
        if not _claim(key):
            continue
        title = (
            "قياس مستحق" if status == "due" else "قياس فات وقته"
        )
        body = (
            f"حان وقت قياس {kind_name}."
            if status == "due"
            else f"فات وقت قياس {kind_name} ولم يُسجَّل."
        )
        notify(
            Push(recipients, PushMessage(title, body, f"measurement_{status}"))
        )


def _scan_appointments(now: datetime) -> None:
    """One reminder, the day before, to the companions or the circle."""
    tomorrow = (now.astimezone(RIYADH) + timedelta(days=1)).date()
    with transaction() as session:
        rows = list(
            session.execute(
                select(Appointment, Patient)
                .join(Patient, Patient.id == Appointment.patient_id)
                .where(
                    Appointment.status == "scheduled",
                    Appointment.scheduled_on == tomorrow,
                )
            )
        )
        for appointment, patient in rows:
            key = f"appointment_reminder:{appointment.id}"
            if not _claim(key):
                continue
            companions = set(
                session.scalars(
                    select(AppointmentCompanion.account_id).where(
                        AppointmentCompanion.appointment_id == appointment.id
                    )
                )
            )
            recipients = (
                companions
                if companions
                else _circle_recipients(session, patient.care_circle_id)
            )
            if patient.account_id is not None:
                recipients = set(recipients) | {patient.account_id}
            specialty = appointment.specialty
            notify(
                Push(
                    tuple(recipients),
                    PushMessage(
                        "موعد غدًا",
                        f"موعد {specialty} غدًا.",
                        "appointment_reminder",
                    ),
                )
            )
