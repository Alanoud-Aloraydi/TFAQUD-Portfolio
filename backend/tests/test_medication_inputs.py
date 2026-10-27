"""Medication validation that does not require a database."""

from datetime import date, datetime, time, timezone
from decimal import Decimal

import pytest
from pydantic import ValidationError

from app.medications.inputs import DoseRecordRequest, OccurrenceQuery
from app.medications.inputs import PlanRequest
from app.medications.plans import normalize_medication_name


def schedule(**changes):
    value = {
        "time_of_day": time(8),
        "dose_value": Decimal("1"),
        "dose_unit": "tablet",
        "weekdays": [1, 3, 5],
    }
    value.update(changes)
    return value


def plan(**changes):
    value = {
        "name": "Medicine",
        "dosage_form": "tablet",
        "treatment_starts_on": date(2026, 10, 1),
        "schedules": [schedule()],
    }
    value.update(changes)
    return value


def test_name_normalization_preserves_a_single_comparison_key():
    assert normalize_medication_name("  ＭＥＤ  Name ") == "med name"


def test_plan_rejects_a_unit_that_does_not_match_its_form():
    with pytest.raises(ValidationError, match="Dose unit"):
        PlanRequest.model_validate(
            plan(schedules=[schedule(dose_unit="mL")])
        )


def test_plan_rejects_duplicate_time_on_the_same_weekday():
    with pytest.raises(ValidationError, match="cannot repeat"):
        PlanRequest.model_validate(
            plan(schedules=[schedule(), schedule(weekdays=[1, 2])])
        )


def test_occurrence_query_accepts_at_most_thirty_two_days():
    query = OccurrenceQuery.model_validate(
        {"from": "2026-10-01", "to": "2026-11-01"}
    )
    assert query.to_date == date(2026, 11, 1)
    with pytest.raises(ValidationError, match="at most 32 days"):
        OccurrenceQuery.model_validate(
            {"from": "2026-10-01", "to": "2026-11-02"}
        )


def test_taken_dose_requires_time_and_rejects_skip_details():
    with pytest.raises(ValidationError, match="actual time"):
        DoseRecordRequest(outcome="taken")
    with pytest.raises(ValidationError, match="skip reason"):
        DoseRecordRequest(
            outcome="taken",
            taken_at=datetime(2026, 10, 1, tzinfo=timezone.utc),
            skip_reason_note="Later",
        )


def test_skipped_dose_does_not_accept_a_taken_time():
    with pytest.raises(ValidationError, match="cannot include"):
        DoseRecordRequest(
            outcome="skipped",
            taken_at=datetime(2026, 10, 1, tzinfo=timezone.utc),
        )
