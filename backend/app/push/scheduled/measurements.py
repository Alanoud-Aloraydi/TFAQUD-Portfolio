"""The missed measurements of the scan: «قياس فائت»."""

from datetime import date, datetime, time
from uuid import UUID

from app import metrics
from app.clock import local_moment, patient_today, patient_zone
from app.database import transaction
from app.measurements.queries import MeasurementQueries
from app.push.missed_texts import MEASUREMENT_TITLE, measurement_missed_text
from app.push.scheduled.audience import (
    circle_patient,
    read_audience,
    tell_audience,
)
from app.push.scheduled.claims import claim_once, occurrence_key
from app.snoozes.queries import put_off_until


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
        key = occurrence_key(occurrence["version_id"], occurrence)
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
            MEASUREMENT_TITLE,
            "measurement_missed",
            lambda name, own, reading=reading: measurement_missed_text(
                reading, name=name, own=own, patient=audience.patient_name
            ),
        )
