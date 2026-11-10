"""A clock the app asks for the time, so tests can move time forward.

Code never calls `datetime.now()` directly. It calls `clock.now()`.

  SystemClock  - the real time. Used by the running server.
  ManualClock  - time that only moves when told to. Used by tests and by
                 scripts/walkthrough.py, which is how token expiry is checked
                 without waiting 15 minutes or 30 days.
"""

from datetime import datetime, timedelta, timezone


class SystemClock:
    """The real time, always in UTC."""
    def now(self) -> datetime:
        """The time now, in UTC."""
        return datetime.now(timezone.utc)


class ManualClock:
    """A clock that moves only when a test moves it."""
    def __init__(self, start: datetime | None = None):
        """Start at `start`, or at 15 October 2026, 12:00 UTC."""
        self._now = start or datetime(
            2026, 10, 15, 12, 0, 0, tzinfo=timezone.utc
        )

    def now(self) -> datetime:
        """The time the clock was set to."""
        return self._now

    def advance(self, **kwargs) -> None:
        """Move forward: advance(minutes=20) or advance(days=31)."""
        self._now += timedelta(**kwargs)
