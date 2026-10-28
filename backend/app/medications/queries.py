"""Read models for medication plans and calculated occurrences."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.errors import NotFound
from app.medications.occurrence_builder import build_occurrences
from app.medications.representations import plan_response
from app.medications.representations import schedule_responses
from app.models import MedicationDoseRecord, MedicationPlan
from app.models import MedicationPlanVersion, MedicationSchedule
from app.models import MedicationScheduleDay, Patient


class MedicationQueries:
    """Read plans and derive scheduled occurrences without storing them."""

    def __init__(self, session: Session, now: datetime):
        self.session = session
        self.now = now

    def plans(self, circle_id: UUID) -> list[dict]:
        patient = self._patient(circle_id)
        latest = (
            select(func.max(MedicationPlanVersion.version_number))
            .where(
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id
            )
            .correlate(MedicationPlan)
            .scalar_subquery()
        )
        rows = self.session.execute(
            select(MedicationPlan, MedicationPlanVersion)
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .where(
                MedicationPlan.patient_id == patient.id,
                MedicationPlanVersion.version_number == latest,
            )
            .order_by(
                MedicationPlan.discontinued_at.is_not(None),
                MedicationPlanVersion.name,
                MedicationPlan.id,
            )
        )
        plans = []
        for plan, version in rows:
            item = plan_response(plan, version)
            item["version"]["schedules"] = schedule_responses(
                self.session, version.id
            )
            plans.append(item)
        return plans

    def plan(self, circle_id: UUID, plan_id: UUID) -> dict:
        patient = self._patient(circle_id)
        row = self.session.execute(
            select(MedicationPlan, MedicationPlanVersion)
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .where(
                MedicationPlan.id == plan_id,
                MedicationPlan.patient_id == patient.id,
            )
            .order_by(MedicationPlanVersion.version_number.desc())
            .limit(1)
        ).one_or_none()
        if row is None:
            raise NotFound("The medication plan does not exist.")
        plan, version = row
        result = plan_response(plan, version)
        result["version"]["schedules"] = schedule_responses(
            self.session, version.id
        )
        return result

    def occurrences(
        self,
        circle_id: UUID,
        from_date: date,
        to_date: date,
        plan_id: UUID | None = None,
    ) -> list[dict]:
        patient = self._patient(circle_id)
        statement = (
            select(
                MedicationPlan,
                MedicationPlanVersion,
                MedicationSchedule,
                MedicationScheduleDay.weekday,
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
            .join(
                MedicationScheduleDay,
                MedicationScheduleDay.schedule_id == MedicationSchedule.id,
            )
            .where(
                MedicationPlan.patient_id == patient.id,
                MedicationPlanVersion.treatment_starts_on <= to_date,
                (
                    MedicationPlanVersion.treatment_ends_on.is_(None)
                    | (
                        MedicationPlanVersion.treatment_ends_on
                        >= from_date
                    )
                ),
            )
        )
        if plan_id is not None:
            statement = statement.where(MedicationPlan.id == plan_id)
        rows = list(self.session.execute(statement))
        schedule_ids = {row[2].id for row in rows}
        records = self._records(schedule_ids, from_date, to_date)
        return build_occurrences(
            rows, records, from_date, to_date, self.now
        )

    def _patient(self, circle_id: UUID) -> Patient:
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
        )
        if patient is None:
            raise NotFound("The patient does not exist.")
        return patient

    def _records(
        self,
        schedule_ids: set[UUID],
        from_date: date,
        to_date: date,
    ) -> dict[tuple[UUID, date], MedicationDoseRecord]:
        if not schedule_ids:
            return {}
        rows = self.session.scalars(
            select(MedicationDoseRecord).where(
                MedicationDoseRecord.schedule_id.in_(schedule_ids),
                MedicationDoseRecord.scheduled_on.between(
                    from_date, to_date
                ),
            )
        )
        return {(row.schedule_id, row.scheduled_on): row for row in rows}
