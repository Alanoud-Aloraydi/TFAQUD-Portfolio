"""A clock the app asks for the time, so tests can move time forward.

Code never calls `datetime.now()` directly. It calls `clock.now()`.

  SystemClock  - the real time. Used by the running server.
  ManualClock  - time that only moves when told to. Used by tests, which is
                 how token expiry is checked without waiting 15 minutes.

Every calendar rule of a circle (schedules, "today", birth dates) follows
the patient's own IANA zone, `CareCircle.time_zone`, whoever records and
wherever their phone is. `patient_zone`, `patient_today` and `local_moment`
are the only ways the server reads it; `latest_today` is the bound for a
date that has no patient yet.
"""

from app.clock.clocks import Clock, ManualClock, SystemClock
from app.clock.zones import (
    DEFAULT_ZONE,
    as_utc,
    is_zone,
    latest_today,
    local_moment,
    patient_today,
    patient_zone,
)

__all__ = [
    "Clock",
    "DEFAULT_ZONE",
    "ManualClock",
    "SystemClock",
    "as_utc",
    "is_zone",
    "latest_today",
    "local_moment",
    "patient_today",
    "patient_zone",
]
