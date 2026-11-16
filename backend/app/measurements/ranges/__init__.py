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
  pressure, the AHA goal of 130/80 is the top of normal."""

from app.measurements.ranges.choosing import (
    all_ranges,
    judge,
    meal_state,
    patient_codes,
    profile_for,
    range_for,
    range_response,
    state_group,
)
from app.measurements.ranges.glucose import GlucoseRange
from app.measurements.ranges.pressure import PressureRange
from app.measurements.ranges.tables import (
    FASTING_STATES,
    GLUCOSE,
    LEVELS,
    MEAL_STATES,
    PRESSURE,
)

__all__ = [
    "FASTING_STATES",
    "GLUCOSE",
    "GlucoseRange",
    "LEVELS",
    "MEAL_STATES",
    "PRESSURE",
    "PressureRange",
    "all_ranges",
    "judge",
    "meal_state",
    "patient_codes",
    "profile_for",
    "range_for",
    "range_response",
    "state_group",
]
