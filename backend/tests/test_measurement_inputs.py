"""Measurement request validation independent of the database."""

from datetime import date, datetime, time, timezone

import pytest
from pydantic import ValidationError

from app.measurements.inputs import PlanRequest, ReadingRequest


def test_plan_requires_user_target_and_unique_days():
    """Reject missing targets and duplicate schedule days."""
    base = dict(
        kind="glucose",
        time_of_day=time(8),
        weekdays=[1, 3],
        starts_on=date.today(),
    )
    with pytest.raises(ValidationError):
        PlanRequest(**base)
    with pytest.raises(ValidationError):
        PlanRequest(**{**base, "weekdays": [1, 1]},
                    glucose_low=80, glucose_high=140)
    value = PlanRequest(**base, glucose_low=80, glucose_high=140)
    assert value.glucose_low == 80


def test_reading_shape_and_blood_pressure_order():
    """Only an explicit valid outcome can be stored."""
    now = datetime.now(timezone.utc)
    with pytest.raises(ValidationError):
        ReadingRequest(kind="bp", outcome="read", measured_at=now,
                       value_one=80, value_two=130)
    with pytest.raises(ValidationError):
        ReadingRequest(kind="glucose", outcome="skipped", value_one=100)
    value = ReadingRequest(kind="bp", outcome="read", measured_at=now,
                           value_one=130, value_two=80)
    assert value.value_two == 80


def _times_plan(times, kind="glucose", **changes):
    target = (
        {"glucose_low": 80, "glucose_high": 140}
        if kind == "glucose"
        else {"systolic_limit": 140, "diastolic_limit": 90}
    )
    return {
        "kind": kind,
        "times": times,
        "weekdays": [1, 3],
        "starts_on": date.today().isoformat(),
        **target,
        **changes,
    }


def test_a_plan_has_several_reading_times_a_day():
    value = PlanRequest.model_validate(
        _times_plan(
            [
                {"time_of_day": "14:00", "glucose_context": "after_meal"},
                {"time_of_day": "07:00", "glucose_context": "fasting"},
            ]
        )
    )
    assert [item.time_of_day for item in value.sorted_times] == [
        time(7),
        time(14),
    ]
    # The first time, the copy a version keeps for an older app.
    assert value.time_of_day == time(7)
    assert value.glucose_context == "fasting"


def test_an_older_app_sends_one_time():
    value = PlanRequest.model_validate(
        {
            "kind": "glucose",
            "time_of_day": "08:30",
            "glucose_context": "before_meal",
            "weekdays": [2],
            "starts_on": date.today().isoformat(),
            "glucose_low": 80,
            "glucose_high": 140,
        }
    )
    assert len(value.times) == 1
    assert value.times[0].time_of_day == time(8, 30)
    assert value.times[0].glucose_context == "before_meal"


@pytest.mark.parametrize(
    "plan, message",
    [
        (_times_plan([]), "at least 1"),
        (
            _times_plan([{"time_of_day": "07:00"}, {"time_of_day": "07:00"}]),
            "cannot repeat",
        ),
        (
            _times_plan(
                [{"time_of_day": f"{hour:02d}:00"} for hour in range(7)]
            ),
            "at most 6",
        ),
        (
            _times_plan(
                [{"time_of_day": "07:00", "glucose_context": "fasting"}],
                kind="bp",
            ),
            "upper limits",
        ),
    ],
)
def test_reading_times_are_valid(plan, message):
    with pytest.raises(ValidationError, match=message):
        PlanRequest.model_validate(plan)
