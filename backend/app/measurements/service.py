"""Transactional measurement-plan and reading rules."""

from datetime import date, datetime, time, timedelta
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from app.clock import as_utc, local_moment, patient_today, patient_zone
from app.errors import Conflict, NotFound, ValidationFailed
from app.measurements.inputs import PlanRequest, ReadingRequest
from app.models import CareCircle, MeasurementPlan, MeasurementPlanTime
from app.models import MeasurementPlanVersion, MeasurementPlanWeekday
from app.models import MeasurementReading, MeasurementTarget

TARGET_FIELDS = (
    "glucose_low", "glucose_high", "systolic_limit", "diastolic_limit",
)


def circle_for(session: Session, circle_id: UUID) -> CareCircle:
    """Find the circle (its patient) without leaking other circles."""
    circle = session.get(CareCircle, circle_id)
    if circle is None:
        raise NotFound()
    return circle


def plan_times(
    session: Session, version_ids
) -> dict[UUID, list[MeasurementPlanTime]]:
    """The reading times of each version, earliest first."""
    ids = list(version_ids)
    result: dict[UUID, list[MeasurementPlanTime]] = {key: [] for key in ids}
    if ids:
        for item in session.scalars(
            select(MeasurementPlanTime)
            .where(MeasurementPlanTime.plan_version_id.in_(ids))
            .order_by(MeasurementPlanTime.time_of_day)
        ):
            result[item.plan_version_id].append(item)
    return result


def plan_weekdays(session: Session, version_ids) -> dict[UUID, list[int]]:
    """The ISO weekdays of each version, Monday first."""
    ids = list(version_ids)
    result: dict[UUID, list[int]] = {key: [] for key in ids}
    if ids:
        for item in session.scalars(
            select(MeasurementPlanWeekday)
            .where(MeasurementPlanWeekday.plan_version_id.in_(ids))
            .order_by(MeasurementPlanWeekday.weekday)
        ):
            result[item.plan_version_id].append(item.weekday)
    return result


def outside_target(
    reading: MeasurementReading, version: MeasurementPlanVersion | None
) -> bool | None:
    """Compare a reading with the target active for its occurrence."""
    # Glucose: below the low or above the high. None when there is no target.
    if reading.kind == "glucose":
        low = version.glucose_low if version else reading.glucose_low
        high = version.glucose_high if version else reading.glucose_high
        if low is None or high is None:
            return None
        return reading.glucose_value < low or reading.glucose_value > high
    # Blood pressure: at or above either upper limit.
    systolic = version.systolic_limit if version else reading.systolic_limit
    diastolic = (
        version.diastolic_limit if version else reading.diastolic_limit
    )
    if systolic is None or diastolic is None:
        return None
    return (
        reading.systolic_value >= systolic
        or reading.diastolic_value >= diastolic
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
        # Not in the past of the patient's own day; the circle is locked,
        # and has no other plan of this kind in use.
        circle = self.session.get(CareCircle, circle_id, with_for_update=True)
        if circle is None:
            raise NotFound()
        if body.starts_on < patient_today(circle, self.now):
            raise ValidationFailed(code="measurement_start_in_past")
        existing = self.session.scalar(
            select(MeasurementPlan.id).where(
                MeasurementPlan.care_circle_id == circle.id,
                MeasurementPlan.kind == body.kind,
                MeasurementPlan.stopped_at.is_(None),
            )
        )
        if existing is not None:
            raise Conflict(code="measurement_active_plan_exists")
        # The plan, its first version, and its target saved for readings
        # without a plan.
        plan = MeasurementPlan(
            care_circle_id=circle.id,
            kind=body.kind,
            created_by_account_id=actor_id,
            created_at=self.now,
        )
        self.session.add(plan)
        self.session.flush()
        self._add_version(plan.id, 1, body.starts_on, body, actor_id)
        self._save_target(circle.id, body.kind, body)
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
                .where(MeasurementPlanVersion.measurement_plan_id == plan.id)
                .order_by(MeasurementPlanVersion.version_number)
            )
        )
        latest = versions[-1]
        today = self._today(plan.care_circle_id)
        if latest.version_number != body.expected_version_number:
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
            plan.id, latest.version_number + 1, effective, body, actor_id
        )
        return plan

    def stop(
        self, circle_id: UUID, plan_id: UUID, actor_id: UUID
    ) -> MeasurementPlan:
        """Stop future tasks immediately and retain every recorded reading;
        say who stopped it."""
        plan = self._plan(circle_id, plan_id)
        # Stop it once; the target of its version in force is kept for readings
        # without a plan.
        if plan.stopped_at is None:
            plan.stopped_at = self.now
            plan.stopped_by_account_id = actor_id
            version = self.session.scalar(
                select(MeasurementPlanVersion)
                .where(
                    MeasurementPlanVersion.measurement_plan_id == plan.id,
                    MeasurementPlanVersion.effective_from_on
                    <= self._today(plan.care_circle_id),
                )
                .order_by(MeasurementPlanVersion.version_number.desc())
            )
            if version is not None:
                self._save_target(plan.care_circle_id, plan.kind, version)
            self.session.flush()
        return plan

    def record(
        self,
        circle_id: UUID,
        actor_id: UUID,
        body: ReadingRequest,
        *,
        plan_version_id: UUID | None = None,
        scheduled_on: date | None = None,
        scheduled_time: time | None = None,
    ) -> MeasurementReading:
        """Write one outcome, linked to a task or as a reading outside a
        plan. A task is a version's reading time on a day; a version with
        one reading time needs no `scheduled_time`.
        """
        circle = circle_for(self.session, circle_id)
        # A reading's time carries its offset and is not in the future.
        if body.measured_at is not None:
            if body.measured_at.tzinfo is None:
                raise ValidationFailed(code="measurement_time_offset_required")
            if body.measured_at > self.now:
                raise ValidationFailed(code="future_measurement")
        target = None
        # Outside a plan: only «read», with no day of a plan.
        if plan_version_id is None:
            if scheduled_on is not None or body.outcome != "read":
                raise ValidationFailed(code="measurement_link_required")
            # Lock the circle, so two first readings cannot save two targets.
            self.session.get(CareCircle, circle.id, with_for_update=True)
            # A plan in force sets the target; a reading cannot send another
            # one.
            target = self._active_target(circle.id, body.kind)
            supplied = any(
                getattr(body, field) is not None for field in TARGET_FIELDS
            )
            if target is not None and supplied and not all(
                getattr(body, field) == getattr(target, field)
                for field in TARGET_FIELDS
            ):
                raise Conflict(code="measurement_target_from_plan")
            # Without a plan: the target sent with the reading is saved, or the
            # saved one is used; one is needed.
            if target is None:
                if supplied:
                    target = self._save_target(circle.id, body.kind, body)
                else:
                    target = self.session.scalar(
                        select(MeasurementTarget).where(
                            MeasurementTarget.care_circle_id == circle.id,
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
            if any(
                getattr(body, field) is not None for field in TARGET_FIELDS
            ):
                raise ValidationFailed(code="measurement_target_linked")
            if scheduled_on is None:
                raise ValidationFailed(code="measurement_date_required")
            scheduled_time = self._require_task(
                circle, plan_version_id, scheduled_on, body.kind,
                scheduled_time,
            )
            existing = self.session.scalar(
                select(MeasurementReading)
                .where(
                    MeasurementReading.plan_version_id == plan_version_id,
                    MeasurementReading.scheduled_on == scheduled_on,
                    MeasurementReading.scheduled_time == scheduled_time,
                )
                .with_for_update()
            )
            if existing is not None:
                raise Conflict(code="measurement_reading_conflict")
        # Save the outcome with a copy of the target it was judged by, so a
        # later target change keeps old readings as they were.
        linked = plan_version_id is not None
        reading = MeasurementReading(
            care_circle_id=circle.id,
            plan_version_id=plan_version_id,
            scheduled_on=scheduled_on,
            scheduled_time=scheduled_time if linked else None,
            kind=body.kind,
            outcome=body.outcome,
            measured_at=as_utc(body.measured_at),
            glucose_value=body.glucose_value,
            systolic_value=body.systolic_value,
            diastolic_value=body.diastolic_value,
            conditions=list(body.conditions),
            other_text=body.other_text,
            note=body.note,
            skip_reason_code=body.skip_reason_code,
            skip_reason_note=body.skip_reason_note,
            recorded_by_account_id=actor_id,
            recorded_at=self.now,
            **{
                field: getattr(target, field) if target else None
                for field in TARGET_FIELDS
            },
        )
        self.session.add(reading)
        self.session.flush()
        return reading

    def _active_target(
        self, care_circle_id: UUID, kind: str
    ) -> MeasurementPlanVersion | None:
        """Use the active plan target when a schedule exists."""
        # The newest version in force today of the kind's plan in use, else its
        # version still to start.
        versions = list(self.session.scalars(
            select(MeasurementPlanVersion)
            .join(
                MeasurementPlan,
                MeasurementPlan.id
                == MeasurementPlanVersion.measurement_plan_id,
            )
            .where(
                MeasurementPlan.care_circle_id == care_circle_id,
                MeasurementPlan.kind == kind,
                MeasurementPlan.stopped_at.is_(None),
            )
            .order_by(MeasurementPlanVersion.version_number.desc())
        ))
        today = self._today(care_circle_id)
        return next(
            (version for version in versions
             if version.effective_from_on <= today),
            versions[-1] if versions else None,
        )

    def _save_target(
        self, care_circle_id: UUID, kind: str,
        source: PlanRequest | ReadingRequest | MeasurementPlanVersion,
    ) -> MeasurementTarget:
        """Keep one durable target without changing prior reading snapshots."""
        # The kind's saved target, locked, made when there is none; then the
        # four limits copied from `source`.
        target = self.session.scalar(
            select(MeasurementTarget).where(
                MeasurementTarget.care_circle_id == care_circle_id,
                MeasurementTarget.kind == kind,
            ).with_for_update()
        )
        if target is None:
            target = MeasurementTarget(
                care_circle_id=care_circle_id, kind=kind
            )
            self.session.add(target)
        for field in TARGET_FIELDS:
            setattr(target, field, getattr(source, field))
        self.session.flush()
        return target

    def follow_up(
        self, circle_id: UUID, reading_id: UUID
    ) -> MeasurementReading:
        """Acknowledge a saved reading without changing its numeric result."""
        # The patient's reading (not a skip), locked.
        circle = circle_for(self.session, circle_id)
        reading = self.session.scalar(
            select(MeasurementReading)
            .where(
                MeasurementReading.id == reading_id,
                MeasurementReading.care_circle_id == circle.id,
                MeasurementReading.outcome == "read",
            )
            .with_for_update()
        )
        if reading is None:
            raise NotFound()
        # Only a reading outside its target is followed up; marking it again
        # keeps the first time.
        version = (
            self.session.get(MeasurementPlanVersion, reading.plan_version_id)
            if reading.plan_version_id
            else None
        )
        if version is None and outside_target(reading, None) is None:
            raise ValidationFailed(code="measurement_no_target")
        if not outside_target(reading, version):
            raise ValidationFailed(code="measurement_within_target")
        if reading.followed_up_at is None:
            reading.followed_up_at = self.now
            self.session.flush()
        return reading

    def _today(self, care_circle_id: UUID) -> date:
        """The patient's calendar day now, in their own zone."""
        return patient_today(
            self.session.get(CareCircle, care_circle_id), self.now
        )

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MeasurementPlan:
        """The circle's measurement plan with this id; 404 for another's."""
        circle = circle_for(self.session, circle_id)
        plan = self.session.scalar(
            select(MeasurementPlan)
            .where(
                MeasurementPlan.id == plan_id,
                MeasurementPlan.care_circle_id == circle.id,
            )
            .with_for_update()
        )
        if plan is None:
            raise NotFound()
        return plan

    def _require_task(
        self,
        circle: CareCircle,
        plan_version_id: UUID,
        scheduled_on: date,
        kind: str,
        scheduled_time: time | None,
    ) -> time:
        """The reading time this task is, after checking the task exists."""
        if scheduled_on > patient_today(circle, self.now):
            raise ValidationFailed(code="future_measurement_task")
        # The circle's plan of this kind with this version, its plan row
        # locked so the task is recorded once.
        row = self.session.execute(
            select(MeasurementPlan, MeasurementPlanVersion)
            .join(
                MeasurementPlanVersion,
                MeasurementPlanVersion.measurement_plan_id
                == MeasurementPlan.id,
            )
            .where(
                MeasurementPlanVersion.id == plan_version_id,
                MeasurementPlan.care_circle_id == circle.id,
                MeasurementPlan.kind == kind,
            )
            .with_for_update(of=MeasurementPlan)
        ).first()
        if row is None:
            raise NotFound()
        plan, version = row
        # Without a time: fine while the version has one reading time.
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
        weekdays = plan_weekdays(self.session, [version.id])[version.id]
        if (
            scheduled_time not in times
            or scheduled_on < version.effective_from_on
            or (
                version.effective_until_on is not None
                and scheduled_on >= version.effective_until_on
            )
            or scheduled_on.isoweekday() not in weekdays
            or (
                plan.stopped_at is not None
                and local_moment(
                    scheduled_on, scheduled_time, patient_zone(circle)
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
        version.effective_from_on = effective
        version.created_by_account_id = actor_id
        version.missed_after_minutes = body.missed_after_minutes
        for field in TARGET_FIELDS:
            setattr(version, field, getattr(body, field))
        # Its reading times and weekdays are replaced too.
        for model in (MeasurementPlanTime, MeasurementPlanWeekday):
            self.session.execute(
                delete(model).where(model.plan_version_id == version.id)
            )
        self.session.flush()
        self._add_days_and_times(version.id, body)

    def _has_readings(self, version: MeasurementPlanVersion) -> bool:
        """Whether any task of this version has an outcome."""
        return self.session.scalar(
            select(MeasurementReading.id)
            .where(MeasurementReading.plan_version_id == version.id)
            .limit(1)
        ) is not None

    def _add_version(
        self,
        measurement_plan_id: UUID,
        version_number: int,
        effective: date,
        body: PlanRequest,
        actor_id: UUID | None,
    ) -> MeasurementPlanVersion:
        """A new version with its weekdays and reading times."""
        version = MeasurementPlanVersion(
            measurement_plan_id=measurement_plan_id,
            version_number=version_number,
            effective_from_on=effective,
            created_by_account_id=actor_id,
            missed_after_minutes=body.missed_after_minutes,
            **{field: getattr(body, field) for field in TARGET_FIELDS},
        )
        self.session.add(version)
        self.session.flush()
        self._add_days_and_times(version.id, body)
        return version

    def _add_days_and_times(
        self, plan_version_id: UUID, body: PlanRequest
    ) -> None:
        """Save the version's weekdays and planned reading times."""
        self.session.add_all(
            MeasurementPlanWeekday(
                plan_version_id=plan_version_id, weekday=weekday
            )
            for weekday in sorted(body.weekdays)
        )
        self.session.add_all(
            MeasurementPlanTime(
                plan_version_id=plan_version_id,
                time_of_day=item.time_of_day,
                measurement_state=item.measurement_state,
            )
            for item in body.sorted_times
        )
        self.session.flush()
