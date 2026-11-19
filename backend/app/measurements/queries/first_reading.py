"""The patient's first day with something saved in «السجل»: the app goes
back no further, and shows no month at all before there is one."""

from datetime import date
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.clock import patient_zone
from app.measurements.service import circle_for
from app.models import MeasurementReading


def first_reading_on(session: Session, circle_id: UUID) -> date | None:
    """The first of the patient's days with a reading (by when it was
    measured) or a skip (by its task's day); None while there is none."""
    circle = circle_for(session, circle_id)
    mine = MeasurementReading.care_circle_id == circle.id
    measured = session.scalar(
        select(func.min(MeasurementReading.measured_at)).where(
            mine, MeasurementReading.outcome == "read"
        )
    )
    skipped = session.scalar(
        select(func.min(MeasurementReading.scheduled_on)).where(
            mine, MeasurementReading.outcome == "skipped"
        )
    )
    days = [skipped] if skipped else []
    if measured:
        days.append(measured.astimezone(patient_zone(circle)).date())
    return min(days, default=None)
