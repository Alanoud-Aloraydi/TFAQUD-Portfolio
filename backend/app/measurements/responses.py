"""A plan version and a reading as the API answers them."""

from app.accounts import recorder_response
from app.measurements.ranges import judge
from app.models import (
    MeasurementPlanTime,
    MeasurementPlanVersion,
    MeasurementReading,
)


def version_response(
    version: MeasurementPlanVersion,
    times: list[MeasurementPlanTime],
    weekdays: list[int],
) -> dict:
    """Return editable version fields without presentation strings."""
    return {
        "id": str(version.id),
        "version_number": version.version_number,
        "effective_from_on": version.effective_from_on.isoformat(),
        "effective_until_on": (
            version.effective_until_on.isoformat()
            if version.effective_until_on
            else None
        ),
        # The weekdays as numbers, 1 (Monday) to 7.
        "weekdays": list(weekdays),
        "missed_after_minutes": version.missed_after_minutes,
        # Every reading time and its planned glucose measurement state.
        "times": [
            {
                "time_of_day": item.time_of_day.strftime("%H:%M"),
                "measurement_state": item.measurement_state,
            }
            for item in times
        ],
    }


def reading_response(
    reading: MeasurementReading,
    accounts: dict | None = None,
    *,
    codes: frozenset[str] = frozenset(),
    planned: str | None = None,
) -> dict:
    """Return a saved outcome and where it falls in its normal range: the
    range of the patient's conditions (`codes`) and its meal state (its own,
    else the `planned` one of its plan time)."""
    # A skip has neither.
    level, normal = judge(reading, codes, planned)
    return {
        "id": str(reading.id),
        "plan_version_id": (
            str(reading.plan_version_id) if reading.plan_version_id else None
        ),
        "scheduled_on": (
            reading.scheduled_on.isoformat() if reading.scheduled_on else None
        ),
        "scheduled_time": (
            reading.scheduled_time.strftime("%H:%M")
            if reading.scheduled_time
            else None
        ),
        "kind": reading.kind,
        "outcome": reading.outcome,
        "measured_at": (
            reading.measured_at.isoformat() if reading.measured_at else None
        ),
        "glucose_value": reading.glucose_value,
        "systolic_value": reading.systolic_value,
        "diastolic_value": reading.diastolic_value,
        "conditions": list(reading.conditions),
        "other_text": reading.other_text,
        "note": reading.note,
        "skip_reason_code": reading.skip_reason_code,
        "skip_reason_note": reading.skip_reason_note,
        "level": level,
        "normal_range": normal,
        # For builds older than the fixed ranges: anything but normal.
        "outside_target": None if level is None else level != "normal",
        "followed_up_at": (
            reading.followed_up_at.isoformat()
            if reading.followed_up_at
            else None
        ),
        "recorded_at": reading.recorded_at.isoformat(),
        "recorded_by": recorder_response(
            (accounts or {}).get(reading.recorded_by_account_id)
        ),
    }
