"""Which days a weekly or a monthly medicine schedule has a dose on."""

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
        # November has 30 days: the 31st moves to the 30th.
        ([31], date(2026, 11, 30), True),
        ([31], date(2026, 12, 31), True),
        ([31], date(2026, 12, 30), False),
        # February 2027 has 28 days, February 2028 has 29.
        ([29, 30, 31], date(2027, 2, 28), True),
        ([30], date(2028, 2, 29), True),
        ([30], date(2028, 2, 28), False),
        ([28], date(2028, 2, 28), True),
    ],
)
def test_monthly_moves_a_missing_day_to_the_months_end(
    month_days, day, expected
):
    assert applies_on("monthly", [], month_days, day) is expected


def test_monthly_ignores_weekdays():
    assert not applies_on("monthly", [1], [3], date(2026, 11, 2))
