"""Which range a reading is judged by, and its level in it."""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.measurements.ranges.tables import (
    FASTING_STATES,
    GLUCOSE,
    MEAL_STATES,
    PRESSURE,
)
from app.models import PatientCondition


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
