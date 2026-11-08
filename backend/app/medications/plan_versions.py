"""Build and compare immutable medication-plan versions."""

from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.medications.inputs import PlanRequest
from app.medications.schedule_days import load_days
from app.models import MedicationPlan, MedicationPlanVersion
from app.models import MedicationSchedule, MedicationScheduleDay
from app.models import MedicationScheduleMonthDay


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
    for item in body.schedules:
        schedule = MedicationSchedule(
            plan_version_id=version.id,
            time_of_day=item.time_of_day,
            dose_value=item.dose_value,
            dose_unit=item.dose_unit,
            instructions=item.instructions,
            repeat=item.repeat,
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
        and version.strength_value == body.strength_value
        and version.strength_unit == body.strength_unit
        and version.dosage_form == body.dosage_form
        and version.reason_for_use == body.reason_for_use
        and version.instructions == body.instructions
        and version.missed_after_minutes == body.missed_after_minutes
        and version.treatment_starts_on == body.treatment_starts_on
        and version.treatment_ends_on == body.treatment_ends_on
    )
    if not fields_match:
        return False
    schedules = list(
        session.scalars(
            select(MedicationSchedule).where(
                MedicationSchedule.plan_version_id == version.id
            )
        )
    )
    days = load_days(session, schedules)
    stored = {
        (
            schedule.time_of_day,
            schedule.dose_value,
            schedule.dose_unit,
            schedule.instructions,
            schedule.repeat,
            kind,
            day,
        )
        for schedule in schedules
        for kind, values in (
            ("weekday", days[schedule.id].weekdays),
            ("month_day", days[schedule.id].month_days),
        )
        for day in values
    }
    requested = {
        (
            item.time_of_day,
            item.dose_value,
            item.dose_unit,
            item.instructions,
            item.repeat,
            kind,
            day,
        )
        for item in body.schedules
        for kind, values in (
            ("weekday", item.weekdays),
            ("month_day", item.month_days),
        )
        for day in values
    }
    return stored == requested
