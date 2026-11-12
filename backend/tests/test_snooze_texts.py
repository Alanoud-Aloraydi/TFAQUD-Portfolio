"""The Arabic count of a time put off, in the reminder of the circle."""

from datetime import time

import pytest

from app.snoozes.due import clock_text, minutes_text


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
        (90, "ساعة و30 دقيقة"),
        (135, "ساعتين و15 دقيقة"),
        (120, "ساعتين"),
        (180, "3 ساعات"),
        (240, "4 ساعات"),
        (605, "10 ساعات و5 دقائق"),
        (660, "11 ساعة"),
        (720, "12 ساعة"),
    ],
)
def test_minutes_read_as_arabic_counts(minutes, text):
    assert minutes_text(minutes) == text


@pytest.mark.parametrize(
    ("moment", "text"),
    [
        (time(0, 5), "12:05 ص"),
        (time(8, 0), "8:00 ص"),
        (time(12, 0), "12:00 م"),
        (time(17, 45), "5:45 م"),
    ],
)
def test_a_wall_time_reads_as_the_app_shows_it(moment, text):
    assert clock_text(moment) == text
