"""Transactional measurement-plan and reading rules."""

from datetime import date, datetime, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound, ValidationFailed
from app.measurements.inputs import PlanRequest, ReadingRequest
from app.models import MeasurementPlan, MeasurementPlanVersion
from app.models import MeasurementRecord, MeasurementTarget, Patient

RIYADH = ZoneInfo("Asia/Riyadh")


def patient_for_circle(session: Session, circle_id: UUID) -> Patient:
    """Find the patient without leaking other circle identities."""
    patient = session.scalar(
        select(Patient).where(Patient.care_circle_id == circle_id)
    )
    if patient is None:
        raise NotFound()
    return patient


def weekday_mask(days: list[int]) -> int:
    """Store ISO weekdays in one constrained integer."""
    return sum(1 << (day - 1) for day in days)


def outside_target(
    record: MeasurementRecord, version: MeasurementPlanVersion | None
) -> bool | None:
    """Compare a reading with the target active for its occurrence."""
    if record.kind == "glucose":
        low = version.glucose_low if version else record.glucose_low
        high = version.glucose_high if version else record.glucose_high
        if low is None or high is None:
            return None
        return (
            record.value_one < low
            or record.value_one > high
        )
    systolic = version.systolic_limit if version else record.systolic_limit
    diastolic = version.diastolic_limit if version else record.diastolic_limit
    if systolic is None or diastolic is None:
        return None
    return (
        record.value_one >= systolic
        or record.value_two >= diastolic
    )


class MeasurementService:
    """Own plan revisions and explicit readings in the caller's transaction."""

    def __init__(self, session: Session, now: datetime):
        self.session = session
        self.now = now

    def create(
        self, circle_id: UUID, actor_id: UUID, body: PlanRequest
    ) -> MeasurementPlan:
        """Create a plan from its first effective day."""
        if body.starts_on < self.now.astimezone(RIYADH).date():
            raise ValidationFailed(code="measurement_start_in_past")
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
            .with_for_update()
        )
        if patient is None:
            raise NotFound()
        existing = self.session.scalar(
            select(MeasurementPlan.id).where(
                MeasurementPlan.patient_id == patient.id,
                MeasurementPlan.kind == body.kind,
                MeasurementPlan.stopped_at.is_(None),
            )
        )
        if existing is not None:
            raise Conflict(code="measurement_active_plan_exists")
        plan = MeasurementPlan(
            patient_id=patient.id,
            kind=body.kind,
            created_by_account_id=actor_id,
            created_at=self.now,
        )
        self.session.add(plan)
        self.session.flush()
        self.session.add(
            self._version(plan.id, 1, body.starts_on, body, actor_id)
        )
        self._save_target(patient.id, body.kind, body)
        self.session.flush()
        return plan

    def revise(
        self, circle_id: UUID, plan_id: UUID, actor_id: UUID, body
    ) -> MeasurementPlan:
        """Change future occurrences without rewriting prior readings."""
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None or body.kind != plan.kind:
            raise Conflict(code="measurement_plan_changed")
        versions = list(
            self.session.scalars(
                select(MeasurementPlanVersion)
                .where(MeasurementPlanVersion.plan_id == plan.id)
                .order_by(MeasurementPlanVersion.number)
            )
        )
        latest = versions[-1]
        today = self.now.astimezone(RIYADH).date()
        if latest.number != body.expected_version_number:
            raise Conflict(code="measurement_plan_changed")
        if latest.effective_from_on > today:
            if len(versions) != 1:
                raise Conflict(code="measurement_plan_changed")
            effective = body.effective_from_on or today
            if effective < today:
                raise ValidationFailed(code="measurement_effective_date")
            self._replace(latest, effective, body, actor_id)
            return plan
        effective = body.effective_from_on or today
        if effective == latest.effective_from_on == today:
            # The plan began today (added or edited today) and the edit is
            # for today too. With no reading under it yet, the edit replaces
            # it; a reading of today keeps the plan it was taken under, and
            # the edit starts tomorrow. Days are the unit of a version.
            if not self._has_readings(latest):
                self._replace(latest, effective, body, actor_id)
                return plan
            effective = today + timedelta(days=1)
        if effective < today or effective <= latest.effective_from_on:
            raise ValidationFailed(code="measurement_effective_date")
        latest.effective_until_on = effective
        self.session.add(
            self._version(
                plan.id, latest.number + 1, effective, body, actor_id
            )
        )
        self.session.flush()
        return plan

    def stop(self, circle_id: UUID, plan_id: UUID) -> MeasurementPlan:
        """Stop future tasks immediately and retain every recorded reading."""
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is None:
            plan.stopped_at = self.now
            version = self.session.scalar(
                select(MeasurementPlanVersion)
                .where(
                    MeasurementPlanVersion.plan_id == plan.id,
                    MeasurementPlanVersion.effective_from_on
                    <= self.now.astimezone(RIYADH).date(),
                )
                .order_by(MeasurementPlanVersion.number.desc())
            )
            if version is not None:
                self._save_target(plan.patient_id, plan.kind, version)
            self.session.flush()
        return plan

    def record(
        self,
        circle_id: UUID,
        actor_id: UUID,
        body: ReadingRequest,
        *,
        version_id: UUID | None = None,
        scheduled_on: date | None = None,
    ) -> MeasurementRecord:
        """Write one outcome, linked to a task or as a standalone reading."""
        patient = patient_for_circle(self.session, circle_id)
        if body.measured_at is not None:
            if body.measured_at.tzinfo is None:
                raise ValidationFailed(code="measurement_time_offset_required")
            if body.measured_at > self.now:
                raise ValidationFailed(code="future_measurement")
        target = None
        if version_id is None:
            if scheduled_on is not None or body.outcome != "read":
                raise ValidationFailed(code="measurement_link_required")
            self.session.scalar(
                select(Patient.id).where(Patient.id == patient.id)
                .with_for_update()
            )
            target = self._active_target(patient.id, body.kind)
            supplied = any(value is not None for value in (
                body.glucose_low, body.glucose_high,
                body.systolic_limit, body.diastolic_limit,
            ))
            if target is not None and supplied and not all(
                getattr(body, field) == getattr(target, field)
                for field in (
                    "glucose_low", "glucose_high", "systolic_limit",
                    "diastolic_limit",
                )
            ):
                raise Conflict(code="measurement_target_from_plan")
            if target is None:
                if supplied:
                    target = self._save_target(patient.id, body.kind, body)
                else:
                    target = self.session.scalar(
                        select(MeasurementTarget).where(
                            MeasurementTarget.patient_id == patient.id,
                            MeasurementTarget.kind == body.kind,
                        )
                    )
                    if target is None:
                        raise ValidationFailed(code="measurement_target_required")
        else:
            if any(value is not None for value in (
                body.glucose_low, body.glucose_high,
                body.systolic_limit, body.diastolic_limit,
            )):
                raise ValidationFailed(code="measurement_target_linked")
            if scheduled_on is None:
                raise ValidationFailed(code="measurement_date_required")
            self._require_task(patient.id, version_id, scheduled_on, body.kind)
            existing = self.session.scalar(
                select(MeasurementRecord)
                .where(
                    MeasurementRecord.plan_version_id == version_id,
                    MeasurementRecord.scheduled_on == scheduled_on,
                )
                .with_for_update()
            )
            if existing is not None:
                raise Conflict(code="measurement_record_conflict")
        record = MeasurementRecord(
            patient_id=patient.id,
            plan_version_id=version_id,
            scheduled_on=scheduled_on,
            kind=body.kind,
            outcome=body.outcome,
            measured_at=body.measured_at,
            value_one=body.value_one,
            value_two=body.value_two,
            glucose_context=body.glucose_context,
            condition=body.condition,
            note=body.note,
            glucose_low=target.glucose_low if target else None,
            glucose_high=target.glucose_high if target else None,
            systolic_limit=target.systolic_limit if target else None,
            diastolic_limit=target.diastolic_limit if target else None,
            recorded_by_account_id=actor_id,
            recorded_at=self.now,
        )
        self.session.add(record)
        self.session.flush()
        return record

    def _active_target(
        self, patient_id: UUID, kind: str
    ) -> MeasurementPlanVersion | None:
        """Use the active plan target when a schedule exists."""
        versions = list(self.session.scalars(
            select(MeasurementPlanVersion)
            .join(MeasurementPlan,
                  MeasurementPlan.id == MeasurementPlanVersion.plan_id)
            .where(
                MeasurementPlan.patient_id == patient_id,
                MeasurementPlan.kind == kind,
                MeasurementPlan.stopped_at.is_(None),
            )
            .order_by(MeasurementPlanVersion.number.desc())
        ))
        today = self.now.astimezone(RIYADH).date()
        return next(
            (version for version in versions
             if version.effective_from_on <= today),
            versions[-1] if versions else None,
        )

    def _save_target(
        self, patient_id: UUID, kind: str,
        source: PlanRequest | ReadingRequest | MeasurementPlanVersion,
    ) -> MeasurementTarget:
        """Keep one durable target without changing prior reading snapshots."""
        target = self.session.scalar(
            select(MeasurementTarget).where(
                MeasurementTarget.patient_id == patient_id,
                MeasurementTarget.kind == kind,
            ).with_for_update()
        )
        if target is None:
            target = MeasurementTarget(patient_id=patient_id, kind=kind)
            self.session.add(target)
        for field in (
            "glucose_low", "glucose_high", "systolic_limit",
            "diastolic_limit",
        ):
            setattr(target, field, getattr(source, field))
        self.session.flush()
        return target

    def follow_up(self, circle_id: UUID, record_id: UUID) -> MeasurementRecord:
        """Acknowledge a saved reading without changing its numeric result."""
        patient = patient_for_circle(self.session, circle_id)
        record = self.session.scalar(
            select(MeasurementRecord)
            .where(
                MeasurementRecord.id == record_id,
                MeasurementRecord.patient_id == patient.id,
                MeasurementRecord.outcome == "read",
            )
            .with_for_update()
        )
        if record is None:
            raise NotFound()
        version = (
            self.session.get(MeasurementPlanVersion, record.plan_version_id)
            if record.plan_version_id
            else None
        )
        if version is None and outside_target(record, None) is None:
            raise ValidationFailed(code="measurement_no_target")
        if not outside_target(record, version):
            raise ValidationFailed(code="measurement_within_target")
        if record.followed_up_at is None:
            record.followed_up_at = self.now
            self.session.flush()
        return record

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MeasurementPlan:
        patient = patient_for_circle(self.session, circle_id)
        plan = self.session.scalar(
            select(MeasurementPlan)
            .where(
                MeasurementPlan.id == plan_id,
                MeasurementPlan.patient_id == patient.id,
            )
            .with_for_update()
        )
        if plan is None:
            raise NotFound()
        return plan

    def _require_task(
        self,
        patient_id: UUID,
        version_id: UUID,
        scheduled_on: date,
        kind: str,
    ) -> None:
        if scheduled_on > self.now.astimezone(RIYADH).date():
            raise ValidationFailed(code="future_measurement_task")
        row = self.session.execute(
            select(MeasurementPlan, MeasurementPlanVersion)
            .join(
                MeasurementPlanVersion,
                MeasurementPlanVersion.plan_id == MeasurementPlan.id,
            )
            .where(
                MeasurementPlanVersion.id == version_id,
                MeasurementPlan.patient_id == patient_id,
                MeasurementPlan.kind == kind,
            )
            .with_for_update(of=MeasurementPlan)
        ).first()
        if row is None:
            raise NotFound()
        plan, version = row
        if (
            scheduled_on < version.effective_from_on
            or (
                version.effective_until_on is not None
                and scheduled_on >= version.effective_until_on
            )
            or not version.weekdays_mask
            & (1 << (scheduled_on.isoweekday() - 1))
            or (
                plan.stopped_at is not None
                and datetime.combine(scheduled_on, version.time_of_day, RIYADH)
                >= plan.stopped_at
            )
        ):
            raise NotFound()

    def _replace(
        self,
        version: MeasurementPlanVersion,
        effective: date,
        body,
        actor_id: UUID | None = None,
    ) -> None:
        """Change a version that has no history yet, in place."""
        replacement = self._version(
            version.plan_id, version.number, effective, body
        )
        version.effective_from_on = effective
        version.created_by_account_id = actor_id
        version.time_of_day = replacement.time_of_day
        version.weekdays_mask = replacement.weekdays_mask
        version.grace_minutes = replacement.grace_minutes
        version.glucose_context = replacement.glucose_context
        version.glucose_low = replacement.glucose_low
        version.glucose_high = replacement.glucose_high
        version.systolic_limit = replacement.systolic_limit
        version.diastolic_limit = replacement.diastolic_limit
        self.session.flush()

    def _has_readings(self, version: MeasurementPlanVersion) -> bool:
        """Whether any task of this version has an outcome."""
        return self.session.scalar(
            select(MeasurementRecord.id)
            .where(MeasurementRecord.plan_version_id == version.id)
            .limit(1)
        ) is not None

    @staticmethod
    def _version(
        plan_id: UUID,
        number: int,
        effective: date,
        body: PlanRequest,
        actor_id: UUID | None = None,
    ) -> MeasurementPlanVersion:
        return MeasurementPlanVersion(
            plan_id=plan_id,
            number=number,
            effective_from_on=effective,
            created_by_account_id=actor_id,
            time_of_day=body.time_of_day,
            weekdays_mask=weekday_mask(body.weekdays),
            grace_minutes=body.grace_minutes,
            glucose_context=body.glucose_context,
            glucose_low=body.glucose_low,
            glucose_high=body.glucose_high,
            systolic_limit=body.systolic_limit,
            diastolic_limit=body.diastolic_limit,
        )
