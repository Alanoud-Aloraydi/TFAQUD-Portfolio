"""The fixed normal ranges, at each band's edges."""

from types import SimpleNamespace

import pytest

from app.measurements.ranges import all_ranges, judge, meal_state, range_for

NONE = frozenset()
DIABETES = frozenset({"diabetes"})
HYPERTENSION = frozenset({"hypertension", "asthma"})


@pytest.mark.parametrize(
    "value, level",
    [(69, "low"), (70, "normal"), (100, "normal"), (101, "elevated"),
     (125, "elevated"), (126, "high")],
)
def test_fasting_glucose_without_diabetes(value, level):
    assert range_for("glucose", NONE, "fasting").level(value) == level


@pytest.mark.parametrize(
    "value, level",
    [(140, "normal"), (141, "elevated"), (199, "elevated"), (200, "high")],
)
def test_glucose_after_a_meal_without_diabetes(value, level):
    assert range_for("glucose", NONE, "after_meal").level(value) == level


@pytest.mark.parametrize(
    "state, value, level",
    [("before_meal", 79, "low"), ("before_meal", 130, "normal"),
     ("fasting", 131, "elevated"), ("fasting", 181, "high"),
     ("after_meal", 180, "normal"), ("bedtime", 250, "elevated"),
     (None, 251, "high")],
)
def test_glucose_with_diabetes(state, value, level):
    assert range_for("glucose", DIABETES, state).level(value) == level


@pytest.mark.parametrize(
    "codes, systolic, diastolic, level",
    [(NONE, 89, 70, "low"), (NONE, 110, 59, "low"),
     (NONE, 90, 60, "normal"), (NONE, 120, 80, "normal"),
     (NONE, 121, 75, "elevated"), (NONE, 115, 85, "elevated"),
     (NONE, 140, 70, "high"), (NONE, 130, 90, "high"),
     (NONE, 150, 55, "high"),
     (HYPERTENSION, 130, 80, "normal"), (HYPERTENSION, 131, 80, "elevated")],
)
def test_blood_pressure(codes, systolic, diastolic, level):
    found = range_for("blood_pressure", codes)
    assert found.level(systolic, diastolic) == level


def test_the_recorded_meal_state_wins_over_the_planned_one():
    assert meal_state(["stress", "after_meal"], "fasting") == "after_meal"
    assert meal_state(["stress"], "fasting") == "fasting"
    assert meal_state([], None) is None


def test_a_reading_is_judged_with_its_normal_band():
    reading = SimpleNamespace(
        kind="glucose", outcome="read", glucose_value=120, conditions=[],
    )

    assert judge(reading, NONE, "fasting") == ("elevated", {
        "profile": "general", "state": "fasting",
        "glucose_low": 70, "glucose_high": 100,
    })
    assert judge(reading, DIABETES, "fasting")[0] == "normal"
    skipped = SimpleNamespace(kind="glucose", outcome="skipped")
    assert judge(skipped, NONE) == (None, None)


def test_every_range_has_four_bands_that_meet():
    for found in all_ranges(DIABETES | HYPERTENSION):
        levels = [band["level"] for band in found["bands"]]
        assert levels == ["low", "normal", "elevated", "high"]
        key = "glucose" if found["kind"] == "glucose" else "systolic"
        for before, after in zip(found["bands"], found["bands"][1:]):
            assert before[f"{key}_high"] + 1 == after[f"{key}_low"]
