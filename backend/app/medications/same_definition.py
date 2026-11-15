"""Whether an edit is the same as the version it edits."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.medications.inputs import PlanRequest
from app.medications.schedule_loading import load_days
from app.models import MedicationPlanVersion, MedicationSchedule


def same_definition(
    session: Session,
    version: MedicationPlanVersion,
    body: PlanRequest,
    normalized_name: str,
) -> bool:
    """Return whether a request exactly matches a stored version."""
    # First the medicine's own fields, which need no extra reading.
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
    # Then the dose times: each one as a set of (time, dose, unit,
    # instructions, repeat, kind of day, day), so their order does not matter.
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
            ("interval", _interval(schedule.interval_days)),
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
            ("interval", _interval(item.interval_days)),
        )
        for day in values
    }
    return stored == requested


def _interval(interval_days: int | None) -> tuple[int, ...]:
    """An interval schedule's one number, compared like a day."""
    return () if interval_days is None else (interval_days,)
