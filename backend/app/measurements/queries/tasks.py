"""The tasks of a range of days, worked out from the plans."""

from datetime import date, timedelta
from uuid import UUID

from app.accounts import accounts_by_id
from app.clock import patient_zone
from app.measurements.ranges import patient_codes
from app.measurements.service import circle_for, plan_times, plan_weekdays
from app.snoozes.queries import attach_snoozes


class Tasks:
    """Works out tasks."""

    def occurrences(
        self, circle_id: UUID, start: date, end: date
    ) -> list[dict]:
        """Calculate expected tasks instead of persisting pending rows.
        Reading times are wall clock in the patient's own zone."""
        circle = circle_for(self.session, circle_id)
        rows = self._versions_in_range(circle, start, end)
        # Their reading times and weekdays, and the readings already recorded
        # for them in the range.
        version_ids = [version.id for _, version in rows]
        times = plan_times(self.session, version_ids)
        weekdays = plan_weekdays(self.session, version_ids)
        saved = self._saved_readings(version_ids, start, end)
        # Who recorded those readings, read once for all of them, and the
        # patient's conditions that choose their ranges.
        context = (
            accounts_by_id(
                self.session,
                {
                    item.recorded_by_account_id
                    for item in saved.values()
                    if item.recorded_by_account_id is not None
                },
            ),
            patient_codes(self.session, circle.id),
        )
        result = self._tasks(
            rows, (start, end), times, weekdays, saved, context,
            patient_zone(circle),
        )
        # Who put each one off, and until when.
        return attach_snoozes(
            self.session, circle_id, "measurement",
            sorted(
                result,
                key=lambda item: (item["scheduled_on"], item["time_of_day"]),
            ),
            start, end, self.now,
        )

    def _tasks(self, rows, days, times, weekdays, saved, context, zone):
        """Each day: each version in force that day, on one of its weekdays,
        gives one task per reading time."""
        start, end = days
        result = []
        day = start
        while day <= end:
            for plan, version in rows:
                if (
                    day < version.effective_from_on
                    or (
                        version.effective_until_on is not None
                        and day >= version.effective_until_on
                    )
                    or day.isoweekday() not in weekdays[version.id]
                ):
                    continue
                for reading_time in times[version.id]:
                    item = self._occurrence(
                        plan, version, reading_time, day, saved,
                        context, zone,
                    )
                    if item is not None:
                        result.append(item)
            day += timedelta(days=1)
        return result
