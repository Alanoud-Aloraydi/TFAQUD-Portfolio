"""Build and compare immutable medication-plan versions."""

from datetime import date
from uuid import UUID

from sqlalchemy.orm import Session

from app.medications.inputs import PlanRequest
from app.models import (
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
    MedicationScheduleDay,
    MedicationScheduleMonthDay,
)


def add_plan_version(
    session: Session,
    plan: MedicationPlan,
    actor_id: UUID,
    body: PlanRequest,
    number: int,
    normalized_name: str,
    effective_from_on: date,
) -> MedicationPlanVersion:
    """Persist one complete plan version and its dose schedules."""
    # The version: the medicine's fields, from `effective_from_on` on, and who
    # made it.
    version = MedicationPlanVersion(
        medication_plan_id=plan.id,
        version_number=number,
        name=body.name,
        normalized_name=normalized_name,
        strength_value=body.strength_value,
        strength_unit=body.strength_unit,
        dosage_form=body.dosage_form,
        reason_for_use=body.reason_for_use,
        instructions=body.instructions,
        missed_after_minutes=body.missed_after_minutes,
        treatment_starts_on=body.treatment_starts_on,
        treatment_ends_on=body.treatment_ends_on,
        effective_from_on=effective_from_on,
        created_by_account_id=actor_id,
    )
    session.add(version)
    session.flush()
    # Each dose time, then its weekdays and its days of the month (an interval
    # dose keeps its number of days on the dose time itself).
    for item in body.schedules:
        schedule = MedicationSchedule(
            plan_version_id=version.id,
            time_of_day=item.time_of_day,
            dose_value=item.dose_value,
            dose_unit=item.dose_unit,
            instructions=item.instructions,
            repeat=item.repeat,
            interval_days=item.interval_days,
        )
        session.add(schedule)
        session.flush()
        session.add_all(
            MedicationScheduleDay(
                schedule_id=schedule.id,
                weekday=weekday,
            )
            for weekday in sorted(item.weekdays)
        )
        session.add_all(
            MedicationScheduleMonthDay(
                schedule_id=schedule.id,
                month_day=month_day,
            )
            for month_day in sorted(item.month_days)
        )
    session.flush()
    return version
