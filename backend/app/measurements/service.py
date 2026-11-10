"""Transactional measurement-plan and reading rules."""

from datetime import date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import as_utc, local_moment, patient_today, patient_zone
from app.errors import Conflict, NotFound, ValidationFailed
from app.measurements.inputs import PlanRequest, ReadingRequest
from app.models import MeasurementPlan, MeasurementPlanTime
from app.models import MeasurementPlanVersion
from app.models import MeasurementRecord, MeasurementTarget, Patient


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


def plan_times(
    session: Session, version_ids
) -> dict[UUID, list[MeasurementPlanTime]]:
    """The reading times of each version, earliest first."""
    ids = list(version_ids)
    result: dict[UUID, list[MeasurementPlanTime]] = {key: [] for key in ids}
    if ids:
        for item in session.scalars(
            select(MeasurementPlanTime)
            .where(MeasurementPlanTime.version_id.in_(ids))
            .order_by(MeasurementPlanTime.time_of_day)
        ):
            result[item.version_id].append(item)
    return result


def outside_target(
    record: MeasurementRecord, version: MeasurementPlanVersion | None
) -> bool | None:
    """Compare a reading with the target active for its occurrence."""
    # Glucose: below the low or above the high. None when there is no target.
    if record.kind == "glucose":
        low = version.glucose_low if version else record.glucose_low
        high = version.glucose_high if version else record.glucose_high
        if low is None or high is None:
            return None
        return (
            record.value_one < low
            or record.value_one > high
        )
    # Blood pressure: at or above either upper limit.
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
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def create(
        self, circle_id: UUID, actor_id: UUID, body: PlanRequest
    ) -> MeasurementPlan:
        """Create a plan from its first effective day."""
        # Not in the past of the patient's own day; the patient is locked,
        # and has no other plan of this kind in use.
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
            .with_for_update()
        )
        if patient is None:
            raise NotFound()
        if body.starts_on < patient_today(patient, self.now):
            raise ValidationFailed(code="measurement_start_in_past")
        existing = self.session.scalar(
            select(MeasurementPlan.id).where(
                MeasurementPlan.patient_id == patient.id,
                MeasurementPlan.kind == body.kind,
                MeasurementPlan.stopped_at.is_(None),
            )
        )
        if existing is not None:
            raise Conflict(code="measurement_active_plan_exists")
        # The plan, its first version, and its target saved for readings
        # without a plan.
        plan = MeasurementPlan(
            patient_id=patient.id,
            kind=body.kind,
            created_by_account_id=actor_id,
            created_at=self.now,
        )
        self.session.add(plan)
        self.session.flush()
        self._add_version(plan.id, 1, body.starts_on, body, actor_id)
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
        today = self._today(plan.patient_id)
        if latest.number != body.expected_version_number:
            raise Conflict(code="measurement_plan_changed")
        if latest.effective_from_on > today:
            # Not started yet, or an edit that starts later: it has no
            # reading, so this edit changes it in place, and a plan can
            # always be edited again.
            effective = body.effective_from_on or latest.effective_from_on
            if effective < today:
                raise ValidationFailed(code="measurement_effective_date")
            if len(versions) > 1:
                previous = versions[-2]
                if effective <= previous.effective_from_on:
                    raise ValidationFailed(code="measurement_effective_date")
                previous.effective_until_on = effective
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
        self._add_version(
            plan.id, latest.number + 1, effective, body, actor_id
        )
        return plan

    def stop(self, circle_id: UUID, plan_id: UUID) -> MeasurementPlan:
        """Stop future tasks immediately and retain every recorded reading."""
        plan = self._plan(circle_id, plan_id)
        # Stop it once; the target of its version in force is kept for readings
        # without a plan.
        if plan.stopped_at is None:
            plan.stopped_at = self.now
            version = self.session.scalar(
                select(MeasurementPlanVersion)
                .where(
                    MeasurementPlanVersion.plan_id == plan.id,
                    MeasurementPlanVersion.effective_from_on
                    <= self._today(plan.patient_id),
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
        scheduled_time: time | None = None,
    ) -> MeasurementRecord:
        """Write one outcome, linked to a task or as a standalone reading.

        A task is a version's reading time on a day; an older app names no
        time, which is fine while the version has one.
        """
        patient = patient_for_circle(self.session, circle_id)
        # A reading's time carries its offset and is not in the future.
        if body.measured_at is not None:
            if body.measured_at.tzinfo is None:
                raise ValidationFailed(code="measurement_time_offset_required")
            if body.measured_at > self.now:
                raise ValidationFailed(code="future_measurement")
        target = None
        # A standalone reading: only «read», with no day of a plan.
        if version_id is None:
            if scheduled_on is not None or body.outcome != "read":
                raise ValidationFailed(code="measurement_link_required")
            # Lock the patient, so two first readings cannot save two targets.
            self.session.scalar(
                select(Patient.id).where(Patient.id == patient.id)
                .with_for_update()
            )
            # A plan in force sets the target; a reading cannot send another
            # one.
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
            # Without a plan: the target sent with the reading is saved, or the
            # saved one is used; one is needed.
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
                        raise ValidationFailed(
                            code="measurement_target_required"
                        )
        # A reading of a plan's task: the plan sets the target, the task must
        # exist that day, and it is recorded once.
        else:
            if any(value is not None for value in (
                body.glucose_low, body.glucose_high,
                body.systolic_limit, body.diastolic_limit,
            )):
                raise ValidationFailed(code="measurement_target_linked")
            if scheduled_on is None:
                raise ValidationFailed(code="measurement_date_required")
            scheduled_time = self._require_task(
                patient.id, version_id, scheduled_on, body.kind, scheduled_time
            )
            existing = self.session.scalar(
                select(MeasurementRecord)
                .where(
                    MeasurementRecord.plan_version_id == version_id,
                    MeasurementRecord.scheduled_on == scheduled_on,
                    MeasurementRecord.scheduled_time == scheduled_time,
                )
                .with_for_update()
            )
            if existing is not None:
                raise Conflict(code="measurement_record_conflict")
        # Save the outcome with a copy of the target it was judged by, so a
        # later target change keeps old readings as they were.
        record = MeasurementRecord(
            patient_id=patient.id,
            plan_version_id=version_id,
            scheduled_on=scheduled_on,
            scheduled_time=scheduled_time if version_id is not None else None,
            kind=body.kind,
            outcome=body.outcome,
            measured_at=as_utc(body.measured_at),
            value_one=body.value_one,
            value_two=body.value_two,
            conditions=body.codes,
            glucose_context=body.stored_context,
            condition=body.stored_condition,
            other_condition=body.other_condition,
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
        # The newest version in force today of the kind's plan in use, else its
        # version still to start.
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
        today = self._today(patient_id)
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
        # The kind's saved target, locked, made when there is none; then the
        # four limits copied from `source`.
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
        # The patient's reading (not a skip), locked.
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
        # Only a reading outside its target is followed up; marking it again
        # keeps the first time.
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

    def _today(self, patient_id: UUID) -> date:
        """The patient's calendar day now, in their own zone."""
        return patient_today(self.session.get(Patient, patient_id), self.now)

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MeasurementPlan:
        """The patient's measurement plan with this id; 404 for a plan of
        another patient.
        """
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
        scheduled_time: time | None,
    ) -> time:
        """The reading time this task is, after checking the task exists."""
        if scheduled_on > self._today(patient_id):
            raise ValidationFailed(code="future_measurement_task")
        # The patient's plan of this kind with this version, its plan row
        # locked so the task is recorded once.
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
        # An older app names no time: fine while the version has one reading
        # time.
        times = [
            item.time_of_day
            for item in plan_times(self.session, [version.id])[version.id]
        ]
        if scheduled_time is None:
            if len(times) != 1:
                raise ValidationFailed(code="measurement_time_required")
            scheduled_time = times[0]
        # The task exists only at one of the version's times, on a day it is in
        # force and one of its weekdays, and before the plan was stopped.
        if (
            scheduled_time not in times
            or scheduled_on < version.effective_from_on
            or (
                version.effective_until_on is not None
                and scheduled_on >= version.effective_until_on
            )
            or not version.weekdays_mask
            & (1 << (scheduled_on.isoweekday() - 1))
            or (
                plan.stopped_at is not None
                and local_moment(
                    scheduled_on,
                    scheduled_time,
                    patient_zone(self.session.get(Patient, patient_id)),
                ) >= plan.stopped_at
            )
        ):
            raise NotFound()
        return scheduled_time

    def _replace(
        self,
        version: MeasurementPlanVersion,
        effective: date,
        body,
        actor_id: UUID | None = None,
    ) -> None:
        """Change a version that has no history yet, in place."""
        # Take every field of the edit onto the version itself.
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
        # Its reading times are replaced too.
        for item in plan_times(self.session, [version.id])[version.id]:
            self.session.delete(item)
        self.session.flush()
        self._add_times(version.id, body)

    def _has_readings(self, version: MeasurementPlanVersion) -> bool:
        """Whether any task of this version has an outcome."""
        return self.session.scalar(
            select(MeasurementRecord.id)
            .where(MeasurementRecord.plan_version_id == version.id)
            .limit(1)
        ) is not None

    def _add_version(
        self,
        plan_id: UUID,
        number: int,
        effective: date,
        body: PlanRequest,
        actor_id: UUID | None,
    ) -> MeasurementPlanVersion:
        """A new version with its reading times."""
        version = self._version(plan_id, number, effective, body, actor_id)
        self.session.add(version)
        self.session.flush()
        self._add_times(version.id, body)
        return version

    def _add_times(self, version_id: UUID, body: PlanRequest) -> None:
        """Save the version's reading times with their conditions."""
        self.session.add_all(
            MeasurementPlanTime(
                version_id=version_id,
                time_of_day=item.time_of_day,
                conditions=item.codes,
                glucose_context=body.context_of(item),
            )
            for item in body.sorted_times
        )
        self.session.flush()

    @staticmethod
    def _version(
        plan_id: UUID,
        number: int,
        effective: date,
        body: PlanRequest,
        actor_id: UUID | None = None,
    ) -> MeasurementPlanVersion:
        """A new version of the plan from the request: its days, reading time,
        grace minutes and target, from `effective` on.
        """
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
