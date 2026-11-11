"""Limits shared by every kind of care plan.

The app (`MissedAfter` in `app/lib/core/constants/plan_limits.dart`), the
request schemas, the models and migration 0047 use the same numbers.
"""

from typing import Annotated

from pydantic import Field

# Minutes after its scheduled time that a dose or reading counts as missed.
MIN_MISSED_AFTER_MINUTES = 5
MAX_MISSED_AFTER_MINUTES = 360
DEFAULT_MISSED_AFTER_MINUTES = 60

MISSED_AFTER_CHECK = (
    f"missed_after_minutes BETWEEN {MIN_MISSED_AFTER_MINUTES} "
    f"AND {MAX_MISSED_AFTER_MINUTES}"
)

# The request field of that threshold.
MissedAfter = Annotated[
    int,
    Field(ge=MIN_MISSED_AFTER_MINUTES, le=MAX_MISSED_AFTER_MINUTES),
]
