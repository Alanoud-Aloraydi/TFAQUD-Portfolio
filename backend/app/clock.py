"""A clock the app asks for the time, so tests can move time forward.

Code never calls `datetime.now()` directly. It calls `clock.now()`.

  SystemClock  - the real time. Used by the running server.
  ManualClock  - time that only moves when told to. Used by tests and by
                 scripts/walkthrough.py, which is how token expiry is checked
                 without waiting 15 minutes or 30 days.
"""

from datetime import datetime, timedelta, timezone


class SystemClock:
    def now(self) -> datetime:
        return datetime.now(timezone.utc)


class ManualClock:
    def __init__(self, start: datetime | None = None):
        self._now = start or datetime(2026, 10, 15, 12, 0, 0, tzinfo=timezone.utc)

    def now(self) -> datetime:
        return self._now

    def advance(self, **kwargs) -> None:
        """Move forward, for example advance(minutes=20) or advance(days=31)."""
        self._now += timedelta(**kwargs)
