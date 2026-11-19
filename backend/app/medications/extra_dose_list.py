"""The extra doses of «سجّل جرعة الآن» taken in some days."""

from datetime import date, time, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import local_moment, patient_zone
from app.errors import NotFound
from app.medications.extra_dose_view import extra_dose_response
from app.models import CareCircle, MedicationExtraDose, MedicationPlan


def extra_doses_between(
    session: Session,
    circle_id: UUID,
    first: date,
    last: date,
    plan_id: UUID | None = None,
) -> list[dict]:
    """The extra doses taken from `first` to `last`, days of the patient's
    own clock, newest first, optionally of one medicine."""
    patient = session.get(CareCircle, circle_id)
    if patient is None:
        raise NotFound("The care circle does not exist.")
    zone = patient_zone(patient)
    query = (
        select(MedicationExtraDose)
        .join(MedicationPlan)
        .where(
            MedicationPlan.care_circle_id == circle_id,
            MedicationExtraDose.taken_at >= local_moment(first, time(0), zone),
            MedicationExtraDose.taken_at
            < local_moment(last + timedelta(days=1), time(0), zone),
        )
        .order_by(MedicationExtraDose.taken_at.desc())
    )
    if plan_id is not None:
        query = query.where(MedicationExtraDose.medication_plan_id == plan_id)
    return [
        extra_dose_response(session, dose) for dose in session.scalars(query)
    ]
