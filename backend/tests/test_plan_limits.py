"""The «missed after» range is one rule for every kind of plan."""

from datetime import date, time
from decimal import Decimal

import pytest
from pydantic import ValidationError

from app.measurements.inputs import PlanRequest as MeasurementPlan
from app.medications.inputs import PlanRequest as MedicationPlan
from app.models.measurement import MeasurementPlanVersion
from app.models.medication_plan import MedicationPlanVersion
from app.plan_limits import (
    DEFAULT_MISSED_AFTER_MINUTES,
    MAX_MISSED_AFTER_MINUTES,
    MIN_MISSED_AFTER_MINUTES,
)


def medication(**changes):
    value = {
        "name": "Medicine",
        "strength_value": Decimal("500"),
        "strength_unit": "mg",
        "dosage_form": "tablet",
        "treatment_starts_on": date(2026, 10, 1),
        "schedules": [{
            "time_of_day": time(8),
            "dose_value": Decimal("1"),
            "dose_unit": "tablet",
            "weekdays": [1, 3, 5],
        }],
    }
    value.update(changes)
    return MedicationPlan.model_validate(value)


def measurement(**changes):
    value = {
        "kind": "glucose",
        "times": [{"time_of_day": time(8), "measurement_state": "fasting"}],
        "weekdays": [1],
        "starts_on": date(2026, 10, 1),
        "glucose_low": 80,
        "glucose_high": 140,
    }
    value.update(changes)
    return MeasurementPlan.model_validate(value)


@pytest.mark.parametrize("build", [medication, measurement])
def test_default_is_sixty_minutes(build):
    assert build().missed_after_minutes == DEFAULT_MISSED_AFTER_MINUTES == 60


@pytest.mark.parametrize("build", [medication, measurement])
@pytest.mark.parametrize(
    "minutes", [MIN_MISSED_AFTER_MINUTES, 45, MAX_MISSED_AFTER_MINUTES]
)
def test_any_minutes_inside_the_range_are_accepted(build, minutes):
    assert build(missed_after_minutes=minutes).missed_after_minutes == minutes


@pytest.mark.parametrize("build", [medication, measurement])
@pytest.mark.parametrize(
    "minutes", [0, MIN_MISSED_AFTER_MINUTES - 1, MAX_MISSED_AFTER_MINUTES + 1]
)
def test_minutes_outside_the_range_are_refused(build, minutes):
    with pytest.raises(ValidationError):
        build(missed_after_minutes=minutes)


@pytest.mark.parametrize(
    "model", [MedicationPlanVersion, MeasurementPlanVersion]
)
def test_database_check_uses_the_same_range(model):
    checks = [
        str(item.sqltext)
        for item in model.__table__.constraints
        if item.name and item.name.endswith("missed_after_minutes")
    ]
    assert checks == [
        f"missed_after_minutes BETWEEN {MIN_MISSED_AFTER_MINUTES} "
        f"AND {MAX_MISSED_AFTER_MINUTES}"
    ]
