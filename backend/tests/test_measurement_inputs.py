"""Measurement request validation independent of the database."""

from datetime import date, datetime, time, timezone

import pytest
from pydantic import ValidationError

from app.measurements.inputs import PlanRequest, ReadingRequest


def test_plan_requires_user_target_and_unique_days():
    """Reject missing targets and duplicate schedule days."""
    base = dict(
        kind="glucose",
        times=[{"time_of_day": time(8), "measurement_state": "fasting"}],
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
        ReadingRequest(
            kind="blood_pressure", outcome="read", measured_at=now,
            systolic_value=80, diastolic_value=130,
        )
    with pytest.raises(ValidationError):
        ReadingRequest(kind="glucose", outcome="skipped", glucose_value=100)
    value = ReadingRequest(
        kind="blood_pressure", outcome="read", measured_at=now,
        systolic_value=130, diastolic_value=80,
    )
    assert value.diastolic_value == 80


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
                {"time_of_day": "14:00", "measurement_state": "after_meal"},
                {"time_of_day": "07:00", "measurement_state": "fasting"},
            ]
        )
    )
    assert [item.time_of_day for item in value.sorted_times] == [
        time(7),
        time(14),
    ]


@pytest.mark.parametrize(
    "plan, message",
    [
        (_times_plan([]), "at least 1"),
        (
            _times_plan([
                {"time_of_day": "07:00", "measurement_state": "fasting"},
                {"time_of_day": "07:00", "measurement_state": "after_meal"},
            ]),
            "cannot repeat",
        ),
        (
            _times_plan(
                [
                    {
                        "time_of_day": f"{hour:02d}:00",
                        "measurement_state": "fasting",
                    }
                    for hour in range(7)
                ]
            ),
            "at most 6",
        ),
        (
            _times_plan(
                [{"time_of_day": "07:00", "measurement_state": "fasting"}],
                kind="blood_pressure",
            ),
            "Only glucose times require",
        ),
    ],
)
def test_reading_times_are_valid(plan, message):
    with pytest.raises(ValidationError, match=message):
        PlanRequest.model_validate(plan)


def test_a_reading_keeps_its_conditions_as_sent():
    """«ظروف القياس»: several at once, and words for «أخرى»."""
    now = datetime.now(timezone.utc)
    value = ReadingRequest(
        kind="glucose", outcome="read", measured_at=now, glucose_value=120,
        conditions=["exertion", "after_meal"],
    )
    assert value.conditions == ["exertion", "after_meal"]
    assert value.other_text is None

    pressure = ReadingRequest(
        kind="blood_pressure", outcome="read", measured_at=now,
        systolic_value=130, diastolic_value=80, conditions=["other"],
        other_text="  بعد القهوة ",
    )
    assert pressure.other_text == "بعد القهوة"


@pytest.mark.parametrize(
    "kind, conditions",
    [
        ("glucose", ["before_meal", "after_meal"]),
        ("blood_pressure", ["fasting"]),
        ("glucose", ["other", "other"]),
    ],
)
def test_conditions_that_do_not_fit(kind, conditions):
    now = datetime.now(timezone.utc)
    values = (
        {"glucose_value": 120}
        if kind == "glucose"
        else {"systolic_value": 130, "diastolic_value": 80}
    )
    with pytest.raises(ValidationError):
        ReadingRequest(
            kind=kind, outcome="read", measured_at=now,
            conditions=conditions, **values,
        )
