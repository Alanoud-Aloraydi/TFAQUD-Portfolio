"""Circle-scoped measurement plans, occurrences, and readings."""

from datetime import date, datetime, timedelta
from uuid import UUID

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.clock import local_moment, patient_today, patient_zone
from app.measurements.service import (
    outside_target,
    patient_for_circle,
    plan_times,
)
from app.models import MeasurementPlan, MeasurementPlanTime
from app.models import MeasurementPlanVersion
from app.models import MeasurementRecord, MeasurementTarget


def version_response(
    version: MeasurementPlanVersion,
    times: list[MeasurementPlanTime] | None = None,
) -> dict:
    """Return editable version fields without presentation strings.

    `times` are every reading time of a day; `time_of_day` and
    `glucose_context` stay as the first of them, for an older app.
    """
    return {
        "id": str(version.id),
        "number": version.number,
        "effective_from_on": version.effective_from_on.isoformat(),
        "effective_until_on": (
            version.effective_until_on.isoformat()
            if version.effective_until_on
            else None
        ),
        "time_of_day": version.time_of_day.strftime("%H:%M"),
        # The weekdays as numbers, 1 (Monday) to 7, read from the bit mask.
        "weekdays": [
            day
            for day in range(1, 8)
            if version.weekdays_mask & (1 << (day - 1))
        ],
        "grace_minutes": version.grace_minutes,
        "glucose_context": version.glucose_context,
        # Every reading time of the day; `time_of_day` and `glucose_context`
        # above are the first one's, for an older app.
        "times": [
            {
                "time_of_day": item.time_of_day.strftime("%H:%M"),
                "glucose_context": item.glucose_context,
                "conditions": list(item.conditions),
            }
            for item in (times or [])
        ],
        "glucose_low": version.glucose_low,
        "glucose_high": version.glucose_high,
        "systolic_limit": version.systolic_limit,
        "diastolic_limit": version.diastolic_limit,
    }


def reading_response(
    record: MeasurementRecord,
    version: MeasurementPlanVersion | None = None,
    accounts: dict | None = None,
) -> dict:
    """Return a saved outcome and its linked target comparison."""
    # Whether a reading is outside the target it was saved with (a skip has no
    # answer).
    outside = None
    if record.outcome == "read":
        outside = outside_target(record, version)
    return {
        "id": str(record.id),
        "plan_version_id": (
            str(record.plan_version_id) if record.plan_version_id else None
        ),
        "scheduled_on": (
            record.scheduled_on.isoformat() if record.scheduled_on else None
        ),
        "scheduled_time": (
            record.scheduled_time.strftime("%H:%M")
            if record.scheduled_time
            else None
        ),
        "kind": record.kind,
        "outcome": record.outcome,
        "measured_at": (
            record.measured_at.isoformat() if record.measured_at else None
        ),
        "value_one": record.value_one,
        "value_two": record.value_two,
        # The two single fields are for an older app; `conditions` is the list.
        "glucose_context": record.glucose_context,
        "condition": record.condition,
        "conditions": list(record.conditions),
        "other_condition": record.other_condition,
        "note": record.note,
        "outside_target": outside,
        # The target the reading was judged by, saved with it.
        "glucose_low": record.glucose_low,
        "glucose_high": record.glucose_high,
        "systolic_limit": record.systolic_limit,
        "diastolic_limit": record.diastolic_limit,
        "followed_up_at": (
            record.followed_up_at.isoformat()
            if record.followed_up_at
            else None
        ),
        "recorded_at": record.recorded_at.isoformat(),
        "recorded_by": recorder_response(
            (accounts or {}).get(record.recorded_by_account_id)
        ),
    }


class MeasurementQueries:
    """Read only data belonging to the selected circle's patient."""

    def __init__(self, session: Session, now: datetime):
        """Read inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def targets(self, circle_id: UUID) -> list[dict]:
        """Return saved goals and the current active-plan override."""
        patient = patient_for_circle(self.session, circle_id)
        # The targets saved with readings, and the versions of the plans not
        # stopped, newest first.
        stored = list(self.session.scalars(
            select(MeasurementTarget).where(
                MeasurementTarget.patient_id == patient.id
            )
        ))
        plans = list(self.session.execute(
            select(MeasurementPlan, MeasurementPlanVersion)
            .join(MeasurementPlanVersion,
                  MeasurementPlanVersion.plan_id == MeasurementPlan.id)
            .where(
                MeasurementPlan.patient_id == patient.id,
                MeasurementPlan.stopped_at.is_(None),
            )
            .order_by(MeasurementPlanVersion.number.desc())
        ))
        # Per kind: the newest version in force today, else the next one to
        # start.
        active = {}
        future = {}
        today = patient_today(patient, self.now)
        for plan, version in plans:
            future[plan.kind] = (plan, version)
            if version.effective_from_on <= today:
                active.setdefault(plan.kind, (plan, version))
        for kind, value in future.items():
            active.setdefault(kind, value)
        # A plan's target wins over a saved one; a kind with neither is left
        # out.
        result = []
        for kind in ("glucose", "bp"):
            source = active[kind][1] if kind in active else next(
                (item for item in stored if item.kind == kind), None
            )
            if source is None:
                continue
            result.append({
                "kind": kind,
                "glucose_low": source.glucose_low,
                "glucose_high": source.glucose_high,
                "systolic_limit": source.systolic_limit,
                "diastolic_limit": source.diastolic_limit,
                "plan_id": str(active[kind][0].id)
                if kind in active else None,
            })
        return result

    def plans(self, circle_id: UUID) -> list[dict]:
        """Return active and stopped plans with version history."""
        patient = patient_for_circle(self.session, circle_id)
        plans = list(
            self.session.scalars(
                select(MeasurementPlan)
                .where(MeasurementPlan.patient_id == patient.id)
                .order_by(MeasurementPlan.created_at.desc())
            )
        )
        if not plans:
            return []
        versions = list(
            self.session.scalars(
                select(MeasurementPlanVersion)
                .where(
                    MeasurementPlanVersion.plan_id.in_(
                        [plan.id for plan in plans]
                    )
                )
                .order_by(MeasurementPlanVersion.number)
            )
        )
        creators = accounts_by_id(
            self.session,
            {
                plan.created_by_account_id
                for plan in plans
                if plan.created_by_account_id is not None
            }
            | {
                version.created_by_account_id
                for version in versions
                if version.created_by_account_id is not None
            },
        )
        by_plan: dict[UUID, list[MeasurementPlanVersion]] = {}
        for version in versions:
            by_plan.setdefault(version.plan_id, []).append(version)
        times = plan_times(self.session, [version.id for version in versions])
        today = patient_today(patient, self.now)
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
                        creators.get(plan.created_by_account_id)
                    ),
                    # Who made the version in effect now — the same person
                    # as created_by unless the plan was revised since.
                    "last_edited_by": recorder_response(
                        creators.get(current.created_by_account_id)
                    ),
                    "stopped_at": (
                        plan.stopped_at.isoformat()
                        if plan.stopped_at
                        else None
                    ),
                    "version": version_response(current, times[current.id]),
                    "pending_version": (
                        version_response(pending, times[pending.id])
                        if pending
                        else None
                    ),
                    "history": [
                        version_response(item, times[item.id])
                        for item in history
                    ],
                }
            )
        return result

    def occurrences(
        self, circle_id: UUID, start: date, end: date
    ) -> list[dict]:
        """Calculate expected tasks instead of persisting pending rows.

        Reading times are wall clock in the patient's own zone."""
        patient = patient_for_circle(self.session, circle_id)
        # The patient's plan versions in force on some day of the range.
        zone = patient_zone(patient)
        rows = list(
            self.session.execute(
                select(MeasurementPlan, MeasurementPlanVersion)
                .join(
                    MeasurementPlanVersion,
                    MeasurementPlanVersion.plan_id == MeasurementPlan.id,
                )
                .where(
                    MeasurementPlan.patient_id == patient.id,
                    MeasurementPlanVersion.effective_from_on <= end,
                    (
                        MeasurementPlanVersion.effective_until_on.is_(None)
                        | (MeasurementPlanVersion.effective_until_on > start)
                    ),
                )
            )
        )
        # Their reading times, and the readings already recorded for them in
        # the range.
        version_ids = [version.id for _, version in rows]
        times = plan_times(self.session, version_ids)
        saved: dict[tuple[UUID, date, object], MeasurementRecord] = {}
        if version_ids:
            records = self.session.scalars(
                select(MeasurementRecord).where(
                    MeasurementRecord.plan_version_id.in_(version_ids),
                    MeasurementRecord.scheduled_on.between(start, end),
                )
            )
            saved = {
                (
                    item.plan_version_id,
                    item.scheduled_on,
                    item.scheduled_time,
                ): item
                for item in records
            }
        # Who recorded those readings, read once for all of them.
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
                    or not version.weekdays_mask
                    & (1 << (day.isoweekday() - 1))
                ):
                    continue
                for reading_time in times[version.id]:
                    item = self._occurrence(
                        plan, version, reading_time, day, saved, accounts,
                        zone,
                    )
                    if item is not None:
                        result.append(item)
            day += timedelta(days=1)
        return sorted(
            result,
            key=lambda item: (item["scheduled_on"], item["time_of_day"]),
        )

    def _occurrence(
        self, plan, version, reading_time, day, saved, accounts, zone
    ) -> dict | None:
        """One reading time of a version on a day, as a task, or None when
        the plan stopped before it. `deadline_at` keeps the offset of the
        patient's `zone` on that day."""
        # The task's time and its deadline (its time plus the grace minutes).
        scheduled = local_moment(day, reading_time.time_of_day, zone)
        if plan.stopped_at is not None and scheduled >= plan.stopped_at:
            return None
        record = saved.get((version.id, day, reading_time.time_of_day))
        deadline = scheduled + timedelta(minutes=version.grace_minutes)
        # Its status: skipped, read, or read late when recorded; otherwise
        # upcoming, due until the deadline, then missed.
        if record is not None:
            status = (
                "skipped"
                if record.outcome == "skipped"
                else ("read_late" if record.measured_at > deadline else "read")
            )
        elif self.now < scheduled:
            status = "upcoming"
        elif self.now <= deadline:
            status = "due"
        else:
            status = "missed"
        return {
            "plan_id": str(plan.id),
            "version_id": str(version.id),
            "kind": plan.kind,
            "scheduled_on": day.isoformat(),
            "time_of_day": reading_time.time_of_day.strftime("%H:%M"),
            "deadline_at": deadline.astimezone(zone).isoformat(),
            "status": status,
            "glucose_context": reading_time.glucose_context,
            "conditions": list(reading_time.conditions),
            "glucose_low": version.glucose_low,
            "glucose_high": version.glucose_high,
            "systolic_limit": version.systolic_limit,
            "diastolic_limit": version.diastolic_limit,
            "record": (
                reading_response(record, version, accounts) if record else None
            ),
        }

    def readings(self, circle_id: UUID, start: date, end: date) -> list[dict]:
        """Return recorded readings and skips in the requested date range,
        whose days are the patient's own."""
        patient = patient_for_circle(self.session, circle_id)
        # Readings measured in the range (the patient's days), and skips of
        # tasks in it, the last recorded first.
        zone = patient_zone(patient)
        lower = local_moment(start, datetime.min.time(), zone)
        upper = local_moment(
            end + timedelta(days=1), datetime.min.time(), zone
        )
        rows = list(
            self.session.execute(
                select(MeasurementRecord, MeasurementPlanVersion)
                .outerjoin(
                    MeasurementPlanVersion,
                    MeasurementPlanVersion.id
                    == MeasurementRecord.plan_version_id,
                )
                .where(
                    MeasurementRecord.patient_id == patient.id,
                    or_(
                        and_(
                            MeasurementRecord.outcome == "read",
                            MeasurementRecord.measured_at >= lower,
                            MeasurementRecord.measured_at < upper,
                        ),
                        and_(
                            MeasurementRecord.outcome == "skipped",
                            MeasurementRecord.scheduled_on.between(start, end),
                        ),
                    ),
                )
                .order_by(MeasurementRecord.recorded_at.desc())
            )
        )
        # Who recorded them, read once for all.
        accounts = accounts_by_id(
            self.session,
            {
                record.recorded_by_account_id
                for record, _ in rows
                if record.recorded_by_account_id is not None
            },
        )
        return [
            reading_response(record, version, accounts)
            for record, version in rows
        ]

    def all_readings(self, circle_id: UUID) -> list[dict]:
        """Return all saved outcomes for the circle's PDF export."""
        patient = patient_for_circle(self.session, circle_id)
        # Every outcome of the patient, the last recorded first, and who
        # recorded each.
        rows = list(
            self.session.execute(
                select(MeasurementRecord, MeasurementPlanVersion)
                .outerjoin(
                    MeasurementPlanVersion,
                    MeasurementPlanVersion.id
                    == MeasurementRecord.plan_version_id,
                )
                .where(MeasurementRecord.patient_id == patient.id)
                .order_by(MeasurementRecord.recorded_at.desc())
            )
        )
        accounts = accounts_by_id(
            self.session,
            {
                record.recorded_by_account_id
                for record, _ in rows
                if record.recorded_by_account_id is not None
            },
        )
        return [
            reading_response(record, version, accounts)
            for record, version in rows
        ]
