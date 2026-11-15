"""The field types of the measurement bodies: kinds, conditions, values."""

from typing import Annotated, Literal

from pydantic import Field

Kind = Literal["glucose", "blood_pressure"]
# «ظروف القياس»: what was going on at a reading, one or more of them.
Code = Literal[
    "fasting", "before_meal", "after_meal", "bedtime",
    "before_medicine", "after_medicine", "morning",
    "exertion", "stress", "illness", "other",
]
CODES = Code.__args__
# Where the stomach is: one of these at a time.
MEAL_STATES = ("fasting", "before_meal", "after_meal", "bedtime")
# «حالة القياس» of a reading time: the stomach for glucose, the medicine
# and the time of day for pressure. One at a time, and only for its kind.
GLUCOSE_STATES = ("fasting", "before_meal", "after_meal")
PRESSURE_STATES = ("before_medicine", "after_medicine", "morning")
# Blood pressure is not read against a fast or bedtime.
NOT_FOR_BLOOD_PRESSURE = ("fasting", "before_meal", "bedtime")
Value = Annotated[int, Field(ge=1, le=999)]
# What a reading may be. 1 to 999 took a diastolic typed as 18 instead of
# 80, and the health summary a doctor reads carried it. Wide enough for a
# reading worth an ambulance, narrow enough to catch a slip of the finger.
# The app holds the same numbers in
# features/measurements/domain/measurement_limits.dart; change them
# together.
SYSTOLIC_RANGE = (60, 260)
DIASTOLIC_RANGE = (30, 160)
GLUCOSE_RANGE = (20, 600)
Conditions = Annotated[list[Code], Field(max_length=len(CODES))]
MeasurementState = Literal[
    "fasting", "before_meal", "after_meal",
    "before_medicine", "after_medicine", "morning",
]
SkipReason = Literal[
    "forgotten", "equipment_unavailable", "patient_refused", "unwell",
    "other",
]


def check_conditions(kind: str, conditions: list[str]) -> None:
    """Conditions do not repeat, hold one meal state, and suit the kind."""
    if len(set(conditions)) != len(conditions):
        raise ValueError("Conditions cannot repeat.")
    if sum(code in MEAL_STATES for code in conditions) > 1:
        raise ValueError("A reading has one meal state at most.")
    if kind == "blood_pressure" and any(
        code in NOT_FOR_BLOOD_PRESSURE for code in conditions
    ):
        raise ValueError("Blood pressure has no fasting or bedtime.")


def in_range(value: int, bounds: tuple[int, int], name: str) -> None:
    """Refuse a number no reading of [name] can be."""
    low, high = bounds
    if not low <= value <= high:
        raise ValueError(
            f"A {name} reading is between {low} and {high}."
        )
