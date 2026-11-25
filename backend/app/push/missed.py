"""The missed tasks of the scheduled scan: «جرعة فائتة», «قياس فائت», and
«موعد فائت» two hours after a visit's time."""

from datetime import date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import select

from app import metrics
from app.clock import local_moment, patient_today, patient_zone
from app.database import transaction
from app.measurements.queries import MeasurementQueries
from app.medications.queries import MedicationQueries
from app.models.appointment import Appointment, visit_name
from app.push.audience import (
    circle_patient,
    claim_once,
    occurrence_key,
    read_audience,
    tell_audience,
)
from app.push.notify import appointment_target, dose_target, measurement_target
from app.push.texts import (
    MISSED_APPOINTMENT_TITLE,
    MISSED_DOSE_TITLE,
    MISSED_MEASUREMENT_TITLE,
    appointment_missed_text,
    dose_missed_text,
    measurement_missed_text,
)
from app.snoozes.queries import put_off_until


def scan_doses(circle_id: UUID, now: datetime) -> None:
    """Send «جرعة فائتة» once for each of the circle's doses of the
    patient's today whose time passed with nothing recorded.
    """
    # Today's doses and who to tell, read in one short transaction; the pushes
    # go after it.
    with transaction() as session:
        patient = circle_patient(session, circle_id)
        if patient is None:
            return
        today = patient_today(patient, now)
        occurrences = MedicationQueries(session, now).occurrences(
            circle_id, today, today
        )
        moved = put_off_until(session, circle_id, "dose", today)
        audience = read_audience(session, patient)
    for occurrence in occurrences:
        if (
            occurrence["record"] is not None
            or occurrence["timing_state"] != "missed"
        ):
            continue
        # A dose put off («ذكّرني لاحقًا») is missed only once its grace has
        # passed after its new time.
        key = occurrence_key(occurrence["schedule_id"], occurrence)
        until = moved.get(key)
        if until is not None and now <= until + timedelta(
            minutes=occurrence["missed_after_minutes"]
        ):
            continue
        # `claim_once` logs the dose once; a scan that finds it logged sent it
        # already.
        if not claim_once(
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
        tell_audience(
            audience,
            MISSED_DOSE_TITLE,
            "dose_missed",
            lambda name, own, medicine=medicine: dose_missed_text(
                medicine, name=name, own=own, patient=audience.patient_name
            ),
            dose_target(
                circle_id,
                occurrence["schedule_id"],
                occurrence["scheduled_on"],
            ),
        )


def scan_measurements(circle_id: UUID, now: datetime) -> None:
    """Send «قياس فائت» once for each of the circle's reading times of
    the patient's today that passed with nothing recorded.
    """
    # Today's reading times and who to tell, read in one short transaction.
    with transaction() as session:
        patient = circle_patient(session, circle_id)
        if patient is None:
            return
        today = patient_today(patient, now)
        occurrences = MeasurementQueries(session, now).occurrences(
            circle_id, today, today
        )
        moved = put_off_until(session, circle_id, "measurement", today)
        zone = patient_zone(patient)
        audience = read_audience(session, patient)
    for occurrence in occurrences:
        if occurrence["status"] != "missed":
            continue
        # The same for a reading time put off: its grace again after its new
        # time (the grace is the time from the task to its deadline).
        key = occurrence_key(occurrence["plan_version_id"], occurrence)
        until = moved.get(key)
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
        if not claim_once(
            "measurement_missed",
            occurrence["plan_version_id"],
            occurrence["scheduled_on"],
            occurrence["time_of_day"],
        ):
            continue
        metrics.increment("tick.missed_measurement")
        reading = occurrence["kind"]
        tell_audience(
            audience,
            MISSED_MEASUREMENT_TITLE,
            "measurement_missed",
            lambda name, own, reading=reading: measurement_missed_text(
                reading, name=name, own=own, patient=audience.patient_name
            ),
            measurement_target(
                circle_id,
                occurrence["plan_version_id"],
                occurrence["scheduled_on"],
                occurrence["time_of_day"],
            ),
        )


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
            (
                item.id, item.scheduled_on, item.time_of_day,
                visit_name(item.kind, item.other_text),
            )
            for item in session.scalars(
                select(Appointment).where(
                    Appointment.care_circle_id == circle_id,
                    Appointment.status == "scheduled",
                    # Marked «فائت» already: nobody needs telling.
                    Appointment.marked_missed.is_(False),
                    Appointment.scheduled_on.between(
                        today - timedelta(days=1), today
                    ),
                )
            )
        ]
        audience = read_audience(session, patient)
    for appointment_id, day, wall_time, visit in appointments:
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
            MISSED_APPOINTMENT_TITLE,
            "appointment_missed",
            lambda name, own: appointment_missed_text(
                name=name, own=own, patient=audience.patient_name,
                visit=visit,
            ),
            appointment_target(circle_id, appointment_id),
        )
