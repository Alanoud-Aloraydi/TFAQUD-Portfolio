"""JSON-ready medication representations."""

from decimal import Decimal
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import recorder_response
from app.models import MedicationSchedule, MedicationScheduleDay


def plain_number(value: Decimal) -> str:
    """Write a decimal with English digits and no exponent.

    `str(Decimal("500").normalize())` is "5E+2", which the API's own input
    rules refuse; this gives "500". Trailing zeros still go: "0.500" is
    "0.5", and "12.000" is "12".
    """
    return format(value.normalize(), "f")


def schedule_responses(session: Session, version_id: UUID) -> list[dict]:
    """Return schedules with their normalized weekday rows grouped."""
    rows = session.execute(
        select(MedicationSchedule, MedicationScheduleDay.weekday)
        .join(
            MedicationScheduleDay,
            MedicationScheduleDay.schedule_id == MedicationSchedule.id,
        )
        .where(MedicationSchedule.plan_version_id == version_id)
        .order_by(
            MedicationSchedule.time_of_day,
            MedicationScheduleDay.weekday,
        )
    )
    grouped = {}
    for schedule, weekday in rows:
        value = grouped.setdefault(
            schedule.id,
            {
                "id": str(schedule.id),
                "time_of_day": schedule.time_of_day.isoformat(
                    timespec="minutes"
                ),
                "dose_value": plain_number(schedule.dose_value),
                "dose_unit": schedule.dose_unit,
                "instructions": schedule.instructions,
                "weekdays": [],
            },
        )
        value["weekdays"].append(weekday)
    return list(grouped.values())


def plan_response(plan, version) -> dict:
    """Return the stable plan and one selected version."""
    return {
        "id": str(plan.id),
        "created_at": plan.created_at.isoformat(),
        "discontinued_at": (
            plan.discontinued_at.isoformat()
            if plan.discontinued_at
            else None
        ),
        "version": {
            "version_number": version.version_number,
            "name": version.name,
            "strength_value": plain_number(version.strength_value),
            "strength_unit": version.strength_unit,
            "dosage_form": version.dosage_form,
            "reason_for_use": version.reason_for_use,
            "instructions": version.instructions,
            "missed_after_minutes": version.missed_after_minutes,
            "treatment_starts_on": (
                version.treatment_starts_on.isoformat()
            ),
            "treatment_ends_on": (
                version.treatment_ends_on.isoformat()
                if version.treatment_ends_on
                else None
            ),
            "effective_from_on": version.effective_from_on.isoformat(),
            "effective_until_on": (
                version.effective_until_on.isoformat()
                if version.effective_until_on
                else None
            ),
        },
    }


def occurrence_response(
    plan, version, schedule, day, record, accounts, timing_state
) -> dict:
    """Return one calculated occurrence with its optional outcome."""
    return {
        "plan_id": str(plan.id),
        "schedule_id": str(schedule.id),
        "scheduled_on": day.isoformat(),
        "time_of_day": schedule.time_of_day.isoformat(timespec="minutes"),
        "name": version.name,
        "strength_value": plain_number(version.strength_value),
        "strength_unit": version.strength_unit,
        "dosage_form": version.dosage_form,
        "dose_value": plain_number(schedule.dose_value),
        "dose_unit": schedule.dose_unit,
        "instructions": schedule.instructions,
        "missed_after_minutes": version.missed_after_minutes,
        "timing_state": timing_state,
        "record": None if record is None else {
            "id": str(record.id),
            "outcome": record.outcome,
            "taken_at": (
                record.taken_at.isoformat() if record.taken_at else None
            ),
            "skip_reason_code": record.skip_reason_code,
            "skip_reason_note": record.skip_reason_note,
            "recorded_at": record.recorded_at.isoformat(),
            "recorded_by": recorder_response(
                accounts.get(record.recorded_by_account_id)
            ),
        },
    }
