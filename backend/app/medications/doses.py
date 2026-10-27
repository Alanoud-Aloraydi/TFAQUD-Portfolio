"""Idempotent recording of scheduled medication outcomes."""

from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound, ValidationFailed
from app.medications.inputs import DoseRecordRequest
from app.models import MedicationDoseRecord, MedicationPlan
from app.models import MedicationPlanVersion, MedicationSchedule
from app.models import MedicationScheduleDay, Patient


class MedicationDoseService:
    """Record one outcome after validating its schedule and date."""

    def __init__(self, session: Session, now):
        self.session = session
        self.now = now

    def record(
        self,
        circle_id: UUID,
        schedule_id: UUID,
        scheduled_on: date,
        actor_id: UUID,
        body: DoseRecordRequest,
    ) -> MedicationDoseRecord:
        if scheduled_on > self.now.date():
            raise ValidationFailed(
                "A future dose cannot be recorded.",
                code="future_dose_record",
            )
        if body.taken_at is not None:
            if body.taken_at.tzinfo is None:
                raise ValidationFailed(
                    "The taken time must include an offset.",
                    code="taken_time_offset_required",
                )
            if body.taken_at > self.now:
                raise ValidationFailed(
                    "The taken time cannot be in the future.",
                    code="future_taken_time",
                )
        self._require_occurrence(circle_id, schedule_id, scheduled_on)
        existing = self.session.scalar(
            select(MedicationDoseRecord)
            .where(
                MedicationDoseRecord.schedule_id == schedule_id,
                MedicationDoseRecord.scheduled_on == scheduled_on,
            )
            .with_for_update()
        )
        if existing is not None:
            if self._same(existing, body):
                return existing
            raise Conflict(code="dose_record_conflict")
        record = MedicationDoseRecord(
            schedule_id=schedule_id,
            scheduled_on=scheduled_on,
            outcome=body.outcome,
            taken_at=body.taken_at,
            skip_reason_code=body.skip_reason_code,
            skip_reason_note=body.skip_reason_note,
            recorded_by_account_id=actor_id,
            recorded_at=self.now,
        )
        self.session.add(record)
        self.session.flush()
        return record

    def _require_occurrence(
        self,
        circle_id: UUID,
        schedule_id: UUID,
        scheduled_on: date,
    ) -> None:
        row = self.session.execute(
            select(MedicationPlan, MedicationPlanVersion)
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .join(
                MedicationSchedule,
                MedicationSchedule.plan_version_id
                == MedicationPlanVersion.id,
            )
            .join(
                MedicationScheduleDay,
                MedicationScheduleDay.schedule_id == MedicationSchedule.id,
            )
            .join(Patient, Patient.id == MedicationPlan.patient_id)
            .where(
                Patient.care_circle_id == circle_id,
                MedicationSchedule.id == schedule_id,
                MedicationScheduleDay.weekday
                == scheduled_on.isoweekday(),
                MedicationPlanVersion.treatment_starts_on <= scheduled_on,
                (
                    MedicationPlanVersion.treatment_ends_on.is_(None)
                    | (
                        MedicationPlanVersion.treatment_ends_on
                        >= scheduled_on
                    )
                ),
            )
            .with_for_update(of=MedicationPlan)
        ).first()
        if row is None:
            raise NotFound("The scheduled dose does not exist.")
        plan, version = row
        if version.effective_from.date() > scheduled_on:
            raise NotFound("The scheduled dose does not exist.")
        if (
            version.effective_until is not None
            and version.effective_until.date() < scheduled_on
        ):
            raise NotFound("The scheduled dose does not exist.")
        if (
            plan.discontinued_at is not None
            and plan.discontinued_at.date() < scheduled_on
        ):
            raise NotFound("The scheduled dose does not exist.")

    @staticmethod
    def _same(record, body: DoseRecordRequest) -> bool:
        return (
            record.outcome == body.outcome
            and record.taken_at == body.taken_at
            and record.skip_reason_code == body.skip_reason_code
            and record.skip_reason_note == body.skip_reason_note
        )
