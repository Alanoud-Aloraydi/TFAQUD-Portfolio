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
