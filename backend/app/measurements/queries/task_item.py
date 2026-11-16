"""One task of one day as the API answers it."""

from datetime import timedelta

from app.clock import local_moment
from app.measurements.queries.responses import reading_response


class TaskItem:
    """Writes one task."""

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
