"""The fixed normal ranges a reading is judged by (migration 0049).

A glucose reading's range depends on when it was taken (fasting or before a
meal; otherwise after a meal) and on whether the patient has diabetes; a
blood pressure's on whether the patient has high blood pressure. Both
come from the patient's medical file. Each range has four levels: below
normal («low»), normal, above normal («elevated») and high.

- Glucose, no diabetes (CDC): fasting 70–100, 101–125, 126 and above;
  after a meal 70–140, 141–199, 200 and above.
- Glucose, diabetes (ADA targets): before a meal 80–130, up to 180, above;
  after a meal 70–180, up to 250, above.
- Blood pressure (the team's chart): below 90/60 low, up to 120/80 normal,
  up to 139/89 high normal, 140/90 and above high. With high blood
  pressure, the AHA goal of 130/80 is the top of normal.
"""

from dataclasses import dataclass
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import PatientCondition

LEVELS = ("low", "normal", "elevated", "high")
# Where the stomach is; a reading has one of these at most.
MEAL_STATES = ("fasting", "before_meal", "after_meal", "bedtime")
# Judged as fasting; any other reading (after a meal, at bedtime, or with
# no state) is judged as after a meal.
FASTING_STATES = ("fasting", "before_meal")


@dataclass(frozen=True)
class GlucoseRange:
    """mg/dL: the normal band and the top of «elevated»."""

    normal_low: int
    normal_high: int
    elevated_high: int

    def level(self, value: int) -> str:
        """Which of the four levels `value` is in."""
        if value < self.normal_low:
            return "low"
        if value <= self.normal_high:
            return "normal"
        if value <= self.elevated_high:
            return "elevated"
        return "high"

    def bands(self) -> list[dict]:
        """The four levels in order, each with its first and last value
        (None where it has no end)."""
        return [
            _glucose_band("low", None, self.normal_low - 1),
            _glucose_band("normal", self.normal_low, self.normal_high),
            _glucose_band(
                "elevated", self.normal_high + 1, self.elevated_high
            ),
            _glucose_band("high", self.elevated_high + 1, None),
        ]


@dataclass(frozen=True)
class PressureRange:
    """mmHg: the bottom and top of normal, and the top of «elevated»."""

    systolic_low: int
    diastolic_low: int
    systolic_high: int
    diastolic_high: int
    systolic_elevated: int
    diastolic_elevated: int

    def level(self, systolic: int, diastolic: int) -> str:
        """Which of the four levels a reading is in; the worse number
        decides, and high wins over low."""
        if (
            systolic > self.systolic_elevated
            or diastolic > self.diastolic_elevated
        ):
            return "high"
        if systolic < self.systolic_low or diastolic < self.diastolic_low:
            return "low"
        if systolic > self.systolic_high or diastolic > self.diastolic_high:
            return "elevated"
        return "normal"

    def bands(self) -> list[dict]:
        """The four levels in order, as in `GlucoseRange.bands`."""
        return [
            _pressure_band(
                "low", (None, self.systolic_low - 1),
                (None, self.diastolic_low - 1),
            ),
            _pressure_band(
                "normal", (self.systolic_low, self.systolic_high),
                (self.diastolic_low, self.diastolic_high),
            ),
            _pressure_band(
                "elevated",
                (self.systolic_high + 1, self.systolic_elevated),
                (self.diastolic_high + 1, self.diastolic_elevated),
            ),
            _pressure_band(
                "high", (self.systolic_elevated + 1, None),
                (self.diastolic_elevated + 1, None),
            ),
        ]


GLUCOSE = {
    ("general", "fasting"): GlucoseRange(70, 100, 125),
    ("general", "after_meal"): GlucoseRange(70, 140, 199),
    ("diabetes", "fasting"): GlucoseRange(80, 130, 180),
    ("diabetes", "after_meal"): GlucoseRange(70, 180, 250),
}
PRESSURE = {
    "general": PressureRange(90, 60, 120, 80, 139, 89),
    "hypertension": PressureRange(90, 60, 130, 80, 139, 89),
}


def _glucose_band(level: str, low: int | None, high: int | None) -> dict:
    return {"level": level, "glucose_low": low, "glucose_high": high}


def _pressure_band(level: str, systolic: tuple, diastolic: tuple) -> dict:
    return {
        "level": level,
        "systolic_low": systolic[0],
        "systolic_high": systolic[1],
        "diastolic_low": diastolic[0],
        "diastolic_high": diastolic[1],
    }


def patient_codes(session: Session, care_circle_id: UUID) -> frozenset[str]:
    """The condition codes in the patient's medical file."""
    return frozenset(session.scalars(
        select(PatientCondition.code).where(
            PatientCondition.care_circle_id == care_circle_id
        )
    ))


def profile_for(kind: str, codes: frozenset[str]) -> str:
    """Which table a kind is read from for this patient."""
    if kind == "glucose":
        return "diabetes" if "diabetes" in codes else "general"
    return "hypertension" if "hypertension" in codes else "general"


def state_group(state: str | None) -> str:
    """The glucose table a meal state is read from."""
    return "fasting" if state in FASTING_STATES else "after_meal"


def meal_state(conditions, planned: str | None = None) -> str | None:
    """The reading's meal state: the one recorded with it, else the one its
    plan time planned."""
    return next((code for code in conditions if code in MEAL_STATES), planned)


def range_for(kind: str, codes: frozenset[str], state: str | None = None):
    """The range a reading of `kind` in `state` is judged by."""
    profile = profile_for(kind, codes)
    if kind == "glucose":
        return GLUCOSE[(profile, state_group(state))]
    return PRESSURE[profile]


def range_response(
    kind: str, codes: frozenset[str], state: str | None = None
) -> dict:
    """One range with its four bands, as the app draws it."""
    return {
        "kind": kind,
        "profile": profile_for(kind, codes),
        "state": state_group(state) if kind == "glucose" else None,
        "bands": range_for(kind, codes, state).bands(),
    }


def all_ranges(codes: frozenset[str]) -> list[dict]:
    """Every range this patient's readings are judged by."""
    return [
        range_response("glucose", codes, "fasting"),
        range_response("glucose", codes, "after_meal"),
        range_response("blood_pressure", codes),
    ]


def judge(reading, codes: frozenset[str], planned: str | None = None):
    """A recorded reading's level and its normal band, or (None, None) for
    a skip."""
    if reading.outcome != "read":
        return None, None
    state = meal_state(reading.conditions, planned)
    found = range_for(reading.kind, codes, state)
    if reading.kind == "glucose":
        level = found.level(reading.glucose_value)
    else:
        level = found.level(reading.systolic_value, reading.diastolic_value)
    normal = dict(found.bands()[1])
    normal.pop("level")
    return level, {
        "profile": profile_for(reading.kind, codes),
        "state": state_group(state) if reading.kind == "glucose" else None,
        **normal,
    }
