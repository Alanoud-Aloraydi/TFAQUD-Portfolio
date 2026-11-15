"""One dose of a day as the API answers it."""

from app.accounts import recorder_response
from app.medications.representations import plain_number


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
        # What the medicine is for. On the patient's own screen it says
        # more than the strength does: «حبة الضغط», not «81 ملغ».
        "reason_for_use": version.reason_for_use,
        "dose_value": plain_number(schedule.dose_value),
        "dose_unit": schedule.dose_unit,
        "instructions": schedule.instructions,
        "missed_after_minutes": version.missed_after_minutes,
        "timing_state": timing_state,
        # How the dose was recorded, and by whom; null until it is.
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
