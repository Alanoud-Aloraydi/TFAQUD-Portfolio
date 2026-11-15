"""The fixed ranges, by table and meal state, and their levels."""

from app.measurements.ranges.glucose import GlucoseRange
from app.measurements.ranges.pressure import PressureRange

LEVELS = ("low", "normal", "elevated", "high")
# Where the stomach is; a reading has one of these at most.
MEAL_STATES = ("fasting", "before_meal", "after_meal", "bedtime")
# Judged as fasting; any other reading (after a meal, at bedtime, or with
# no state) is judged as after a meal.
FASTING_STATES = ("fasting", "before_meal")

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
