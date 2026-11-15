"""The missed doses of the scan: «جرعة فائتة»."""

from datetime import datetime, timedelta
from uuid import UUID

from app import metrics
from app.clock import patient_today
from app.database import transaction
from app.medications.queries import MedicationQueries
from app.push.missed_texts import DOSE_TITLE, dose_missed_text
from app.push.scheduled.audience import (
    circle_patient,
    read_audience,
    tell_audience,
)
from app.push.scheduled.claims import claim_once, occurrence_key
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
            DOSE_TITLE,
            "dose_missed",
            lambda name, own, medicine=medicine: dose_missed_text(
                medicine, name=name, own=own, patient=audience.patient_name
            ),
        )
