"""The missed appointments of the scan: «موعد فائت», two hours after."""

from datetime import datetime, timedelta
from uuid import UUID

from sqlalchemy import select

from app import metrics
from app.clock import local_moment, patient_today, patient_zone
from app.database import transaction
from app.models.appointment import Appointment
from app.push.missed_texts import APPOINTMENT_TITLE, appointment_missed_text
from app.push.scheduled.audience import (
    circle_patient,
    read_audience,
    tell_audience,
)
from app.push.scheduled.claims import claim_once
from app.push.targets import appointment_target

# An appointment nobody marked visited or cancelled is called missed this
# long after its time; past `APPOINTMENT_TOO_LATE` after that it is no
# longer told (a tick that was down for long sends no stale news).
APPOINTMENT_MISSED_AFTER = timedelta(hours=2)
APPOINTMENT_TOO_LATE = timedelta(hours=12)


def scan_appointments(circle_id: UUID, now: datetime) -> None:
    """Send «موعد فائت» once for each of the circle's appointments whose
    time passed `APPOINTMENT_MISSED_AFTER` ago and that nobody marked
    done («تم الموعد») or cancelled.
    """
    with transaction() as session:
        patient = circle_patient(session, circle_id)
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
        audience = read_audience(session, patient)
    for appointment_id, day, wall_time in appointments:
        missed_at = (
            local_moment(day, wall_time, zone) + APPOINTMENT_MISSED_AFTER
        )
        if not missed_at <= now < missed_at + APPOINTMENT_TOO_LATE:
            continue
        if not claim_once(
            "appointment_missed", str(appointment_id), day.isoformat(), None
        ):
            continue
        metrics.increment("tick.missed_appointment")
        tell_audience(
            audience,
            APPOINTMENT_TITLE,
            "appointment_missed",
            lambda name, own: appointment_missed_text(
                name=name, own=own, patient=audience.patient_name
            ),
            appointment_target(circle_id, appointment_id),
        )
