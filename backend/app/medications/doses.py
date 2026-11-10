"""Idempotent recording of scheduled medication outcomes."""

from datetime import date
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import as_utc, local_moment, patient_today, patient_zone
from app.errors import Conflict, NotFound, ValidationFailed
from app.medications.inputs import DoseRecordRequest
from app.medications.schedule_days import load_days
from app.models import MedicationDoseRecord, MedicationPlan
from app.models import MedicationPlanVersion, MedicationSchedule
from app.models import Patient


class MedicationDoseService:
    """Record one outcome after validating its schedule and date."""

    def __init__(self, session: Session, now):
        """Work inside the caller's session, at the time `now`."""
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
        """Record one dose of today or before, once: the same record again is
        accepted as it is, a different one is a conflict.
        """
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
        )
        if patient is None:
            raise NotFound("The scheduled dose does not exist.")
        # Not a future dose in the patient's own day (whatever day it is where
        # the recorder's phone is), and not a taken time in the future or
        # without its offset.
        if scheduled_on > patient_today(patient, self.now):
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
        # The dose must exist; its record is read locked, so two people
        # recording it at once get one record.
        self._require_occurrence(patient, schedule_id, scheduled_on)
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
            taken_at=as_utc(body.taken_at),
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
        patient: Patient,
        schedule_id: UUID,
        scheduled_on: date,
    ) -> None:
        """404 unless the schedule belongs to the circle's patient and has a
        dose on that day.
        """
        row = self.session.execute(
            select(
                MedicationPlan,
                MedicationPlanVersion,
                MedicationSchedule,
            )
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
            .where(
                MedicationPlan.patient_id == patient.id,
                MedicationSchedule.id == schedule_id,
                MedicationPlanVersion.treatment_starts_on <= scheduled_on,
                MedicationPlanVersion.cancelled_at.is_(None),
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
        plan, version, schedule = row
        # A weekly schedule on its weekday, a monthly one on its day of the
        # month, an interval one every few days from the treatment's start.
        if not load_days(self.session, [schedule])[schedule.id].applies_on(
            scheduled_on, version.treatment_starts_on
        ):
            raise NotFound("The scheduled dose does not exist.")
        if version.effective_from_on > scheduled_on:
            raise NotFound("The scheduled dose does not exist.")
        if (
            version.effective_until_on is not None
            and version.effective_until_on <= scheduled_on
        ):
            raise NotFound("The scheduled dose does not exist.")
        if (
            plan.discontinued_at is not None
            and local_moment(
                scheduled_on, schedule.time_of_day, patient_zone(patient)
            ) >= plan.discontinued_at
        ):
            raise NotFound("The scheduled dose does not exist.")

    @staticmethod
    def _same(record, body: DoseRecordRequest) -> bool:
        """Whether `body` says the same as the saved record."""
        return (
            record.outcome == body.outcome
            and record.taken_at == body.taken_at
            and record.skip_reason_code == body.skip_reason_code
            and record.skip_reason_note == body.skip_reason_note
        )
