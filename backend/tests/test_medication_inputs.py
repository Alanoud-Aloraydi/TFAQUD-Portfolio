"""Medication validation that does not require a database."""

from datetime import date, datetime, time, timezone
from decimal import Decimal

import pytest
from pydantic import ValidationError

from app.measurements.inputs import ReadingQuery
from app.medications.inputs import DoseRecordRequest, OccurrenceQuery
from app.medications.inputs import PlanRequest
from app.medications.occurrence_builder import _timing_state
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
        "strength_value": Decimal("500"),
        "strength_unit": "mg",
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


def test_plan_rejects_localized_or_ambiguous_decimal_text():
    with pytest.raises(ValidationError, match="English digits"):
        PlanRequest.model_validate(
            plan(strength_value="٥٠٠")
        )
    with pytest.raises(ValidationError, match="leading zero"):
        PlanRequest.model_validate(
            plan(strength_value=".5")
        )


def test_injection_accepts_volume_or_units():
    PlanRequest.model_validate(
        plan(
            dosage_form="injection",
            strength_unit="unit/mL",
            schedules=[schedule(dose_unit="mL")],
        )
    )
    PlanRequest.model_validate(
        plan(
            dosage_form="injection",
            strength_unit="unit/mL",
            schedules=[schedule(dose_unit="unit")],
        )
    )


@pytest.mark.parametrize("query_type", [OccurrenceQuery, ReadingQuery])
def test_a_list_covers_at_most_thirty_five_days(query_type):
    # 1 October to 4 November: 35 days, both ends counted.
    query = query_type.model_validate(
        {"from": "2026-10-01", "to": "2026-11-04"}
    )
    assert query.to_date == date(2026, 11, 4)
    with pytest.raises(ValidationError, match="at most 35 days"):
        query_type.model_validate({"from": "2026-10-01", "to": "2026-11-05"})


@pytest.mark.parametrize("query_type", [OccurrenceQuery, ReadingQuery])
def test_a_list_takes_the_app_today_window(query_type):
    """«اليوم» reads 2 overdue days, today and 30 days ahead (33 days); on
    11 November that is 9 November to 11 December."""
    query = query_type.model_validate(
        {"from": "2026-11-09", "to": "2026-12-11"}
    )
    assert (query.to_date - query.from_date).days + 1 == 33


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


def test_skip_note_requires_the_other_reason():
    with pytest.raises(ValidationError, match="other reason"):
        DoseRecordRequest(
            outcome="skipped",
            skip_reason_code="forgotten",
            skip_reason_note="Details",
        )


def test_dose_status_changes_at_due_and_missed_boundaries():
    scheduled = datetime(2026, 11, 2, 8, tzinfo=timezone.utc)

    def state(minutes):
        return _timing_state(
            scheduled,
            scheduled.replace(minute=minutes),
            None,
            30,
        )

    assert state(0) == "due"
    assert state(14) == "due"
    assert state(15) == "late"
    assert state(29) == "late"
    assert state(30) == "missed"


def monthly(**changes):
    value = schedule(repeat="monthly", weekdays=[], month_days=[1, 15])
    value.update(changes)
    return value


def test_a_schedule_without_repeat_is_weekly():
    body = PlanRequest.model_validate(plan())
    assert body.schedules[0].repeat == "weekly"
    assert body.schedules[0].month_days == []


def test_a_monthly_schedule_takes_days_of_the_month():
    body = PlanRequest.model_validate(plan(schedules=[monthly()]))
    assert body.schedules[0].repeat == "monthly"
    assert body.schedules[0].month_days == [1, 15]


@pytest.mark.parametrize(
    "changes, message",
    [
        ({"month_days": []}, "at least one day of the month"),
        ({"month_days": [0]}, "1 to 28"),
        ({"month_days": [29]}, "1 to 28"),
        ({"month_days": [5, 5]}, "cannot repeat"),
        ({"weekdays": [1]}, "no weekdays"),
    ],
)
def test_a_monthly_schedule_needs_valid_days(changes, message):
    with pytest.raises(ValidationError, match=message):
        PlanRequest.model_validate(plan(schedules=[monthly(**changes)]))


def test_a_weekly_schedule_needs_weekdays_and_no_month_days():
    with pytest.raises(ValidationError, match="at least one weekday"):
        PlanRequest.model_validate(plan(schedules=[schedule(weekdays=[])]))
    with pytest.raises(ValidationError, match="no days of the month"):
        PlanRequest.model_validate(
            plan(schedules=[schedule(month_days=[3])])
        )


def test_one_time_is_weekly_or_monthly_not_both():
    with pytest.raises(ValidationError, match="one way only"):
        PlanRequest.model_validate(plan(schedules=[schedule(), monthly()]))


def test_two_monthly_doses_at_one_time_never_meet():
    with pytest.raises(ValidationError, match="day of the month"):
        PlanRequest.model_validate(
            plan(schedules=[monthly(), monthly(month_days=[15, 20])])
        )
    # Different days, and the same day at another time: fine.
    PlanRequest.model_validate(
        plan(
            schedules=[
                monthly(month_days=[1]),
                monthly(month_days=[28], dose_value=Decimal("2")),
                monthly(time_of_day=time(20), month_days=[28]),
            ]
        )
    )


def test_an_interval_schedule_has_its_number_only():
    every = schedule(repeat="interval", weekdays=[], interval_days=3)
    assert PlanRequest(**plan(schedules=[every])).schedules[0].interval_days
    for change in (
        {"interval_days": None},
        {"interval_days": 91},
        {"weekdays": [1]},
        {"month_days": [5]},
    ):
        with pytest.raises(ValidationError):
            PlanRequest(**plan(schedules=[{**every, **change}]))
    with pytest.raises(ValidationError):
        PlanRequest(**plan(schedules=[schedule(interval_days=3)]))


def test_one_dose_time_repeats_in_one_way_only():
    every = schedule(repeat="interval", weekdays=[], interval_days=3)
    with pytest.raises(ValidationError, match="one way only"):
        PlanRequest(**plan(schedules=[every, {**every, "interval_days": 5}]))
    with pytest.raises(ValidationError, match="one way only"):
        PlanRequest(**plan(schedules=[every, schedule(weekdays=[2])]))
    evening = {**every, "time_of_day": time(20)}
    assert len(PlanRequest(**plan(schedules=[every, evening])).schedules) == 2
