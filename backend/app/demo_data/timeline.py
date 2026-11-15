"""The demo's days and moments, counted from `now` in the demo's zone."""

from datetime import date, datetime, time, timedelta

from app.demo_data.story import DEMO_ZONE


class DemoTimeline:
    """Days and moments around now."""

    def day(self, offset: int) -> date:
        """The date `offset` days from today."""
        return self.today + timedelta(days=offset)

    def at(self, offset: int, hour: int = 9, minute: int = 0) -> datetime:
        """Riyadh time on the day `offset` days from today."""
        return datetime.combine(
            self.day(offset), time(hour, minute), tzinfo=DEMO_ZONE
        )

    def clock_in(self, minutes: int) -> str:
        """The «HH:MM» time `minutes` from now, on a five-minute mark and
        kept within today, so a task falls where the story wants it: done,
        late, next or later."""
        moment = self.now + timedelta(minutes=minutes)
        start = datetime.combine(self.today, time(0, 5), tzinfo=DEMO_ZONE)
        end = datetime.combine(self.today, time(23, 55), tzinfo=DEMO_ZONE)
        moment = min(max(moment, start), end)
        return f"{moment.hour:02d}:{moment.minute - moment.minute % 5:02d}"

    def visit_in(self, minutes: int) -> tuple[int, str]:
        """The day (0 today, 1 tomorrow) and «HH:MM» of a visit `minutes`
        from now: today at `clock_in(minutes)` while that is still ahead;
        in the last minutes before midnight, when it is not, tomorrow at
        that time from now, since a visit cannot be made in the past."""
        clock = self.clock_in(minutes)
        hour, minute = (int(part) for part in clock.split(":"))
        today = datetime.combine(
            self.today, time(hour, minute), tzinfo=DEMO_ZONE
        )
        if today >= self.now:
            return 0, clock
        moment = self.now + timedelta(minutes=minutes)
        return 1, f"{moment.hour:02d}:{moment.minute - moment.minute % 5:02d}"
