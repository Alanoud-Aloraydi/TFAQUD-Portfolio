"""Circle-scoped measurement plans, occurrences, and readings."""

from datetime import date, datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import and_, or_, select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.measurements.service import outside_target, patient_for_circle
from app.models import MeasurementPlan, MeasurementPlanVersion
from app.models import MeasurementRecord, MeasurementTarget

RIYADH = ZoneInfo("Asia/Riyadh")


def version_response(version: MeasurementPlanVersion) -> dict:
    """Return editable version fields without presentation strings."""
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
        "weekdays": [
            day
            for day in range(1, 8)
            if version.weekdays_mask & (1 << (day - 1))
        ],
        "grace_minutes": version.grace_minutes,
        "glucose_context": version.glucose_context,
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
        "kind": record.kind,
        "outcome": record.outcome,
        "measured_at": (
            record.measured_at.isoformat() if record.measured_at else None
        ),
        "value_one": record.value_one,
        "value_two": record.value_two,
        "glucose_context": record.glucose_context,
        "condition": record.condition,
        "note": record.note,
        "outside_target": outside,
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
        self.session = session
        self.now = now

    def targets(self, circle_id: UUID) -> list[dict]:
        """Return saved goals and the current active-plan override."""
        patient = patient_for_circle(self.session, circle_id)
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
        active = {}
        future = {}
        today = self.now.astimezone(RIYADH).date()
        for plan, version in plans:
            future[plan.kind] = (plan, version)
            if version.effective_from_on <= today:
                active.setdefault(plan.kind, (plan, version))
        for kind, value in future.items():
            active.setdefault(kind, value)
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
        today = self.now.astimezone(RIYADH).date()
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
                    "version": version_response(current),
                    "pending_version": (
                        version_response(pending) if pending else None
                    ),
                    "history": [version_response(item) for item in history],
                }
            )
        return result

    def occurrences(
        self, circle_id: UUID, start: date, end: date
    ) -> list[dict]:
        """Calculate expected tasks instead of persisting pending rows."""
        patient = patient_for_circle(self.session, circle_id)
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
        version_ids = [version.id for _, version in rows]
        saved: dict[tuple[UUID, date], MeasurementRecord] = {}
        if version_ids:
            records = self.session.scalars(
                select(MeasurementRecord).where(
                    MeasurementRecord.plan_version_id.in_(version_ids),
                    MeasurementRecord.scheduled_on.between(start, end),
                )
            )
            saved = {
                (item.plan_version_id, item.scheduled_on): item
                for item in records
            }
        accounts = accounts_by_id(
            self.session,
            {
                item.recorded_by_account_id
                for item in saved.values()
                if item.recorded_by_account_id is not None
            },
        )
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
                scheduled = datetime.combine(day, version.time_of_day, RIYADH)
                if (
                    plan.stopped_at is not None
                    and scheduled >= plan.stopped_at
                ):
                    continue
                record = saved.get((version.id, day))
                deadline = scheduled + timedelta(minutes=version.grace_minutes)
                if record is not None:
                    status = (
                        "skipped"
                        if record.outcome == "skipped"
                        else (
                            "read_late"
                            if record.measured_at > deadline
                            else "read"
                        )
                    )
                elif self.now < scheduled:
                    status = "upcoming"
                elif self.now <= deadline:
                    status = "due"
                else:
                    status = "missed"
                result.append(
                    {
                        "plan_id": str(plan.id),
                        "version_id": str(version.id),
                        "kind": plan.kind,
                        "scheduled_on": day.isoformat(),
                        "time_of_day": version.time_of_day.strftime("%H:%M"),
                        "deadline_at": deadline.isoformat(),
                        "status": status,
                        "glucose_context": version.glucose_context,
                        "glucose_low": version.glucose_low,
                        "glucose_high": version.glucose_high,
                        "systolic_limit": version.systolic_limit,
                        "diastolic_limit": version.diastolic_limit,
                        "record": (
                            reading_response(record, version, accounts)
                            if record
                            else None
                        ),
                    }
                )
            day += timedelta(days=1)
        return sorted(
            result,
            key=lambda item: (item["scheduled_on"], item["time_of_day"]),
        )

    def readings(self, circle_id: UUID, start: date, end: date) -> list[dict]:
        """Return recorded readings and skips in the requested date range."""
        patient = patient_for_circle(self.session, circle_id)
        lower = datetime.combine(start, datetime.min.time(), RIYADH)
        upper = datetime.combine(
            end + timedelta(days=1), datetime.min.time(), RIYADH
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
