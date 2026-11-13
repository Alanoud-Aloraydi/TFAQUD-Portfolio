"""Circle-scoped measurement plans, occurrences, and readings."""

from datetime import date, datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.clock import local_moment, patient_today, patient_zone
from app.measurements.ranges import all_ranges, judge, patient_codes
from app.measurements.service import circle_for, plan_times, plan_weekdays
from app.models import MeasurementPlan, MeasurementPlanTime
from app.models import MeasurementPlanVersion, MeasurementReading
from app.snoozes.queries import attach_snoozes


def version_response(
    version: MeasurementPlanVersion,
    times: list[MeasurementPlanTime],
    weekdays: list[int],
) -> dict:
    """Return editable version fields without presentation strings."""
    return {
        "id": str(version.id),
        "version_number": version.version_number,
        "effective_from_on": version.effective_from_on.isoformat(),
        "effective_until_on": (
            version.effective_until_on.isoformat()
            if version.effective_until_on
            else None
        ),
        # The weekdays as numbers, 1 (Monday) to 7.
        "weekdays": list(weekdays),
        "missed_after_minutes": version.missed_after_minutes,
        # Every reading time and its planned glucose measurement state.
        "times": [
            {
                "time_of_day": item.time_of_day.strftime("%H:%M"),
                "measurement_state": item.measurement_state,
            }
            for item in times
        ],
    }


def reading_response(
    reading: MeasurementReading,
    accounts: dict | None = None,
    *,
    codes: frozenset[str] = frozenset(),
    planned: str | None = None,
) -> dict:
    """Return a saved outcome and where it falls in its normal range: the
    range of the patient's conditions (`codes`) and its meal state (its own,
    else the `planned` one of its plan time)."""
    # A skip has neither.
    level, normal = judge(reading, codes, planned)
    return {
        "id": str(reading.id),
        "plan_version_id": (
            str(reading.plan_version_id) if reading.plan_version_id else None
        ),
        "scheduled_on": (
            reading.scheduled_on.isoformat() if reading.scheduled_on else None
        ),
        "scheduled_time": (
            reading.scheduled_time.strftime("%H:%M")
            if reading.scheduled_time
            else None
        ),
        "kind": reading.kind,
        "outcome": reading.outcome,
        "measured_at": (
            reading.measured_at.isoformat() if reading.measured_at else None
        ),
        "glucose_value": reading.glucose_value,
        "systolic_value": reading.systolic_value,
        "diastolic_value": reading.diastolic_value,
        "conditions": list(reading.conditions),
        "other_text": reading.other_text,
        "note": reading.note,
        "skip_reason_code": reading.skip_reason_code,
        "skip_reason_note": reading.skip_reason_note,
        "level": level,
        "normal_range": normal,
        # Kept for builds before 0049: anything but normal.
        "outside_target": None if level is None else level != "normal",
        "followed_up_at": (
            reading.followed_up_at.isoformat()
            if reading.followed_up_at
            else None
        ),
        "recorded_at": reading.recorded_at.isoformat(),
        "recorded_by": recorder_response(
            (accounts or {}).get(reading.recorded_by_account_id)
        ),
    }


class MeasurementQueries:
    """Read only data belonging to the selected circle's patient."""

    def __init__(self, session: Session, now: datetime):
        """Read inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def ranges(self, circle_id: UUID) -> dict:
        """Return the fixed normal ranges for this patient's conditions."""
        circle = circle_for(self.session, circle_id)
        codes = patient_codes(self.session, circle.id)
        return {
            # The conditions that choose a range, from the medical file.
            "conditions": sorted(codes & {"diabetes", "hypertension"}),
            "ranges": all_ranges(codes),
        }

    def plans(self, circle_id: UUID) -> list[dict]:
        """Return active and stopped plans with version history."""
        circle = circle_for(self.session, circle_id)
        plans = list(
            self.session.scalars(
                select(MeasurementPlan)
                .where(MeasurementPlan.care_circle_id == circle.id)
                .order_by(MeasurementPlan.created_at.desc())
            )
        )
        if not plans:
            return []
        versions = list(
            self.session.scalars(
                select(MeasurementPlanVersion)
                .where(
                    MeasurementPlanVersion.measurement_plan_id.in_(
                        [plan.id for plan in plans]
                    )
                )
                .order_by(MeasurementPlanVersion.version_number)
            )
        )
        people = accounts_by_id(
            self.session,
            {
                account_id
                for plan in plans
                for account_id in (
                    plan.created_by_account_id, plan.stopped_by_account_id
                )
                if account_id is not None
            }
            | {
                version.created_by_account_id
                for version in versions
                if version.created_by_account_id is not None
            },
        )
        by_plan: dict[UUID, list[MeasurementPlanVersion]] = {}
        for version in versions:
            by_plan.setdefault(version.measurement_plan_id, []).append(version)
        ids = [version.id for version in versions]
        times = plan_times(self.session, ids)
        weekdays = plan_weekdays(self.session, ids)
        today = patient_today(circle, self.now)

        def shown(version):
            return version_response(
                version, times[version.id], weekdays[version.id]
            )

        result = []
        for plan in plans:
            history = by_plan[plan.id]
            current = next(
                (
                    version
                    for version in reversed(history)
                    if version.effective_from_on <= today
                ),
                history[0],
            )
            pending = next(
                (
                    version
                    for version in history
                    if version.effective_from_on > today
                    and version.id != current.id
                ),
                None,
            )
            result.append(
                {
                    "id": str(plan.id),
                    "kind": plan.kind,
                    "created_at": plan.created_at.isoformat(),
                    "created_by": recorder_response(
                        people.get(plan.created_by_account_id)
                    ),
                    # Who made the version in effect now — the same person
                    # as created_by unless the plan was revised since.
                    "last_edited_by": recorder_response(
                        people.get(current.created_by_account_id)
                    ),
                    "stopped_at": (
                        plan.stopped_at.isoformat()
                        if plan.stopped_at
                        else None
                    ),
                    "stopped_by": recorder_response(
                        people.get(plan.stopped_by_account_id)
                    ),
                    "version": shown(current),
                    "pending_version": shown(pending) if pending else None,
                    "history": [shown(item) for item in history],
                }
            )
        return result

    def occurrences(
        self, circle_id: UUID, start: date, end: date
    ) -> list[dict]:
        """Calculate expected tasks instead of persisting pending rows.
        Reading times are wall clock in the patient's own zone."""
        circle = circle_for(self.session, circle_id)
        # The circle's plan versions in force on some day of the range.
        zone = patient_zone(circle)
        rows = list(
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
        # Their reading times and weekdays, and the readings already recorded
        # for them in the range.
        version_ids = [version.id for _, version in rows]
        times = plan_times(self.session, version_ids)
        weekdays = plan_weekdays(self.session, version_ids)
        saved: dict[tuple[UUID, date, object], MeasurementReading] = {}
        if version_ids:
            readings = self.session.scalars(
                select(MeasurementReading).where(
                    MeasurementReading.plan_version_id.in_(version_ids),
                    MeasurementReading.scheduled_on.between(start, end),
                )
            )
            saved = {
                (
                    item.plan_version_id,
                    item.scheduled_on,
                    item.scheduled_time,
                ): item
                for item in readings
            }
        # Who recorded those readings, read once for all of them, and the
        # patient's conditions that choose their ranges.
        codes = patient_codes(self.session, circle.id)
        accounts = accounts_by_id(
            self.session,
            {
                item.recorded_by_account_id
                for item in saved.values()
                if item.recorded_by_account_id is not None
            },
        )
        # Each day: each version in force that day, on one of its weekdays,
        # gives one task per reading time.
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
                        (accounts, codes), zone,
                    )
                    if item is not None:
                        result.append(item)
            day += timedelta(days=1)
        # Who put each one off, and until when.
        return attach_snoozes(
            self.session, circle_id, "measurement",
            sorted(
                result,
                key=lambda item: (item["scheduled_on"], item["time_of_day"]),
            ),
            start, end, self.now,
        )

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

    def readings(self, circle_id: UUID, start: date, end: date) -> list[dict]:
        """Return recorded readings and skips in the requested date range,
        whose days are the patient's own."""
        circle = circle_for(self.session, circle_id)
        # Readings measured in the range (the patient's days), and skips of
        # tasks in it, the last recorded first.
        zone = patient_zone(circle)
        lower = local_moment(start, datetime.min.time(), zone)
        upper = local_moment(
            end + timedelta(days=1), datetime.min.time(), zone
        )
        return self._responses(
            circle.id,
            or_(
                and_(
                    MeasurementReading.outcome == "read",
                    MeasurementReading.measured_at >= lower,
                    MeasurementReading.measured_at < upper,
                ),
                and_(
                    MeasurementReading.outcome == "skipped",
                    MeasurementReading.scheduled_on.between(start, end),
                ),
            ),
        )

    def all_readings(self, circle_id: UUID) -> list[dict]:
        """Return all saved outcomes for the circle's PDF export."""
        circle = circle_for(self.session, circle_id)
        return self._responses(circle.id)

    def _responses(self, circle_id: UUID, *conditions) -> list[dict]:
        """The circle's readings matching `conditions`, the last recorded
        first, each judged by its normal range, with who recorded it."""
        rows = list(
            self.session.execute(
                select(MeasurementReading, MeasurementPlanTime)
                .outerjoin(
                    MeasurementPlanTime,
                    and_(
                        MeasurementPlanTime.plan_version_id
                        == MeasurementReading.plan_version_id,
                        MeasurementPlanTime.time_of_day
                        == MeasurementReading.scheduled_time,
                    ),
                )
                .where(
                    MeasurementReading.care_circle_id == circle_id,
                    *conditions,
                )
                .order_by(MeasurementReading.recorded_at.desc())
            )
        )
        accounts = accounts_by_id(
            self.session,
            {
                reading.recorded_by_account_id
                for reading, _ in rows
                if reading.recorded_by_account_id is not None
            },
        )
        codes = patient_codes(self.session, circle_id)
        return [
            reading_response(
                reading, accounts, codes=codes,
                planned=time.measurement_state if time else None,
            )
            for reading, time in rows
        ]
