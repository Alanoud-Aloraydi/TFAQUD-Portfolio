"""Appointment request validation independent of the database."""

from datetime import date, time, timedelta

import pytest
from pydantic import ValidationError

from app.appointments.inputs import AppointmentRequest


def _visit(**changes) -> dict:
    """A valid request for one visit, with [changes] applied."""
    return {
        "kind": "follow_up",
        "specialty": "عيادة الغدد",
        "scheduled_on": date(2026, 12, 5),
        "time_of_day": time(10, 30),
        "place": "مستشفى الملك فهد",
        **changes,
    }


def test_one_visit_books_no_series():
    """A request without other dates is a visit on its own."""
    assert AppointmentRequest(**_visit()).also_on == []


def test_a_booking_carries_the_other_dates():
    """The clinic's sheet: dates that follow no rule, kept as given."""
    body = AppointmentRequest(
        **_visit(also_on=[date(2027, 1, 9), date(2027, 3, 14)])
    )

    assert body.scheduled_on == date(2026, 12, 5)
    assert body.also_on == [date(2027, 1, 9), date(2027, 3, 14)]


def test_a_date_cannot_be_booked_twice():
    """Two visits on one day would be two rows nobody asked for, whether
    the repeat is among the other dates or against the first."""
    with pytest.raises(ValidationError):
        AppointmentRequest(
            **_visit(also_on=[date(2027, 1, 9), date(2027, 1, 9)])
        )
    with pytest.raises(ValidationError):
        AppointmentRequest(**_visit(also_on=[date(2026, 12, 5)]))


def test_a_booking_has_an_end():
    """A sheet of dates is finite: 24 visits in one booking at most."""
    many = [date(2027, 1, 1) + timedelta(days=n) for n in range(23)]
    assert AppointmentRequest(**_visit(also_on=many))
    with pytest.raises(ValidationError):
        AppointmentRequest(
            **_visit(also_on=[*many, date(2027, 6, 1)])
        )
