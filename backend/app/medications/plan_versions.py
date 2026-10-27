"""Build and compare immutable medication-plan versions."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.medications.inputs import PlanRequest
from app.models import MedicationPlan, MedicationPlanVersion
from app.models import MedicationSchedule, MedicationScheduleDay


def add_plan_version(
    session: Session,
    plan: MedicationPlan,
    actor_id: UUID,
    body: PlanRequest,
    number: int,
    normalized_name: str,
    effective_from,
) -> MedicationPlanVersion:
    """Persist one complete plan version and its dose schedules."""
    version = MedicationPlanVersion(
        medication_plan_id=plan.id,
        version_number=number,
        name=body.name,
        normalized_name=normalized_name,
        strength_text=body.strength_text,
        dosage_form=body.dosage_form,
        reason_for_use=body.reason_for_use,
        instructions=body.instructions,
        treatment_starts_on=body.treatment_starts_on,
        treatment_ends_on=body.treatment_ends_on,
        effective_from=effective_from,
        created_by_account_id=actor_id,
    )
    session.add(version)
    session.flush()
    for item in body.schedules:
        schedule = MedicationSchedule(
            plan_version_id=version.id,
            time_of_day=item.time_of_day,
            dose_value=item.dose_value,
            dose_unit=item.dose_unit,
            instructions=item.instructions,
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
    session.flush()
    return version


def same_definition(
    session: Session,
    version: MedicationPlanVersion,
    body: PlanRequest,
    normalized_name: str,
) -> bool:
    """Return whether a request exactly matches a stored version."""
    fields_match = (
        version.normalized_name == normalized_name
        and version.name == body.name
        and version.strength_text == body.strength_text
        and version.dosage_form == body.dosage_form
        and version.reason_for_use == body.reason_for_use
        and version.instructions == body.instructions
        and version.treatment_starts_on == body.treatment_starts_on
        and version.treatment_ends_on == body.treatment_ends_on
    )
    if not fields_match:
        return False
    rows = session.execute(
        select(MedicationSchedule, MedicationScheduleDay.weekday)
        .join(
            MedicationScheduleDay,
            MedicationScheduleDay.schedule_id == MedicationSchedule.id,
        )
        .where(MedicationSchedule.plan_version_id == version.id)
    )
    stored = {
        (
            schedule.time_of_day,
            schedule.dose_value,
            schedule.dose_unit,
            schedule.instructions,
            weekday,
        )
        for schedule, weekday in rows
    }
    requested = {
        (
            item.time_of_day,
            item.dose_value,
            item.dose_unit,
            item.instructions,
            weekday,
        )
        for item in body.schedules
        for weekday in item.weekdays
    }
    return stored == requested
