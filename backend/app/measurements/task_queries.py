"""The tasks of a range of days, worked out from the plans: the versions
in force, the readings saved, and each task of each day as the API
answers it."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import select

from app.accounts import accounts_by_id
from app.clock import local_moment, patient_zone
from app.measurements.plans import circle_for, plan_times, plan_weekdays
from app.measurements.ranges import patient_codes
from app.measurements.responses import reading_response
from app.models import (
    MeasurementPlan,
    MeasurementPlanVersion,
    MeasurementReading,
)
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

    # Reads versions and saved readings.
    def _versions_in_range(self, circle, start: date, end: date) -> list:
        """The circle's plan versions in force on some day of the range,
        each with its plan."""
        return list(
            self.session.execute(
                select(MeasurementPlan, MeasurementPlanVersion)
                .join(
                    MeasurementPlanVersion,
                    MeasurementPlanVersion.measurement_plan_id
                    == MeasurementPlan.id,
                )
                .where(
                    MeasurementPlan.care_circle_id == circle.id,
                    MeasurementPlanVersion.effective_from_on <= end,
                    (
                        MeasurementPlanVersion.effective_until_on.is_(None)
                        | (MeasurementPlanVersion.effective_until_on > start)
                    ),
                )
            )
        )

    def _saved_readings(self, version_ids, start: date, end: date) -> dict:
        """The readings recorded for those versions in the range, by
        version, day and time."""
        if not version_ids:
            return {}
        readings = self.session.scalars(
            select(MeasurementReading).where(
                MeasurementReading.plan_version_id.in_(version_ids),
                MeasurementReading.scheduled_on.between(start, end),
            )
        )
        return {
            (item.plan_version_id, item.scheduled_on, item.scheduled_time):
            item
            for item in readings
        }

    # Writes one task.
    def _occurrence(
        self, plan, version, reading_time, day, saved, people, zone
    ) -> dict | None:
        """One reading time of a version on a day, as a task, or None when
        the plan stopped before it. `deadline_at` keeps the offset of the
        patient's `zone` on that day; `people` is who recorded readings and
        the patient's condition codes."""
        # The task's time and its deadline (its time plus the minutes after
        # which it is missed).
        scheduled = local_moment(day, reading_time.time_of_day, zone)
        if plan.stopped_at is not None and scheduled >= plan.stopped_at:
            return None
        reading = saved.get((version.id, day, reading_time.time_of_day))
        deadline = scheduled + timedelta(minutes=version.missed_after_minutes)
        # Its status: skipped, read, or read late when recorded; otherwise
        # upcoming, due until the deadline, then missed.
        if reading is not None:
            status = (
                "skipped"
                if reading.outcome == "skipped"
                else (
                    "read_late" if reading.measured_at > deadline else "read"
                )
            )
        elif self.now < scheduled:
            status = "upcoming"
        elif self.now <= deadline:
            status = "due"
        else:
            status = "missed"
        return {
            "plan_id": str(plan.id),
            "plan_version_id": str(version.id),
            "kind": plan.kind,
            "scheduled_on": day.isoformat(),
            "time_of_day": reading_time.time_of_day.strftime("%H:%M"),
            "deadline_at": deadline.astimezone(zone).isoformat(),
            "status": status,
            "measurement_state": reading_time.measurement_state,
            "reading": (
                reading_response(
                    reading, people[0], codes=people[1],
                    planned=reading_time.measurement_state,
                )
                if reading else None
            ),
        }
