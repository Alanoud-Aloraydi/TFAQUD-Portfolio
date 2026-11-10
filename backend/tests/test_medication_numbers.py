"""Doses and strengths are written as plain numbers in the API."""

from decimal import Decimal

import pytest

from app.medications.representations import plain_number


@pytest.mark.parametrize(
    ("stored", "written"),
    [
        ("500.000", "500"),
        ("1000", "1000"),
        ("100.000", "100"),
        ("10", "10"),
        ("12.000", "12"),
        ("0.500", "0.5"),
        ("2.5", "2.5"),
        ("0.125", "0.125"),
    ],
)
def test_plain_number_has_no_exponent(stored, written):
    assert plain_number(Decimal(stored)) == written
