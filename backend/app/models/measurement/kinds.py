"""The kinds of measurement and the database checks the measurement
tables share."""


KINDS = ("glucose", "blood_pressure")
KINDS_SQL = "kind IN ('glucose', 'blood_pressure')"

# «ظروف القياس» a reading time or a reading can have (migration 0025), each
# once (0035).
CONDITIONS_CHECK = (
    "conditions <@ ARRAY['fasting', 'before_meal', 'after_meal', 'bedtime', "
    "'before_medicine', 'after_medicine', 'morning', "
    "'exertion', 'stress', 'illness', 'other']::text[]"
)
CONDITIONS_ONCE = (
    "fn_measurement_conditions_unique(conditions)"
)
TARGET_BY_KIND = (
    "(kind = 'glucose' AND glucose_low IS NOT NULL "
    "AND glucose_high IS NOT NULL AND glucose_low BETWEEN 1 AND 999 "
    "AND glucose_high BETWEEN 1 AND 999 "
    "AND glucose_low < glucose_high AND systolic_limit IS NULL "
    "AND diastolic_limit IS NULL) OR "
    "(kind = 'blood_pressure' AND systolic_limit IS NOT NULL "
    "AND diastolic_limit IS NOT NULL "
    "AND systolic_limit BETWEEN 1 AND 999 "
    "AND diastolic_limit BETWEEN 1 AND 999 "
    "AND systolic_limit > diastolic_limit AND glucose_low IS NULL "
    "AND glucose_high IS NULL)"
)
