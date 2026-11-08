"""Which days a weekly, monthly or interval medicine schedule has a dose
on."""

from datetime import date

import pytest

from app.medications.schedule_days import applies_on


def test_weekly_uses_the_iso_weekday():
    # 2 November 2026 is a Monday.
    assert applies_on("weekly", [1], [], date(2026, 11, 2))
    assert not applies_on("weekly", [2], [], date(2026, 11, 2))


@pytest.mark.parametrize(
    "month_days, day, expected",
    [
        ([15], date(2026, 11, 15), True),
        ([15], date(2026, 11, 16), False),
        ([1, 28], date(2026, 11, 28), True),
        ([1, 28], date(2026, 11, 29), False),
        # February 2027 has 28 days: the 28th is still the 28th.
        ([28], date(2027, 2, 28), True),
        ([28], date(2028, 2, 29), False),
    ],
)
def test_monthly_uses_the_day_of_the_month(month_days, day, expected):
    assert applies_on("monthly", [], month_days, day) is expected


def test_monthly_ignores_weekdays():
    assert not applies_on("monthly", [1], [3], date(2026, 11, 2))


def test_interval_counts_from_the_treatment_start():
    start = date(2026, 11, 1)
    days = [
        day
        for day in range(1, 11)
        if applies_on(
            "interval", [], [], date(2026, 11, day),
            interval_days=3, treatment_starts_on=start,
        )
    ]
    assert days == [1, 4, 7, 10]
    # Nothing before the treatment starts.
    assert not applies_on(
        "interval", [], [], date(2026, 10, 29),
        interval_days=3, treatment_starts_on=start,
    )
    # Every day is every day.
    assert applies_on(
        "interval", [], [], date(2026, 12, 25),
        interval_days=1, treatment_starts_on=start,
    )
