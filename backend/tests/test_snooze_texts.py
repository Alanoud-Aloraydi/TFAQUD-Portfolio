"""The Arabic count of a time put off, in the reminder of the circle."""

import pytest

from app.snoozes.due import minutes_text


@pytest.mark.parametrize(
    ("minutes", "text"),
    [
        (1, "دقيقة"),
        (2, "دقيقتين"),
        (5, "5 دقائق"),
        (10, "10 دقائق"),
        (15, "15 دقيقة"),
        (30, "30 دقيقة"),
        (60, "ساعة"),
        (90, "90 دقيقة"),
        (120, "ساعتين"),
        (180, "3 ساعات"),
        (240, "4 ساعات"),
    ],
)
def test_minutes_read_as_arabic_counts(minutes, text):
    assert minutes_text(minutes) == text
