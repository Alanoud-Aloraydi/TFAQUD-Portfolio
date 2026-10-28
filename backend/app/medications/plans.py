"""Transactional commands for versioned medication plans."""

import unicodedata
from datetime import timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound, ValidationFailed
from app.medications.availability import require_available_name
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plan_versions import add_plan_version
from app.medications.plan_versions import same_definition
from app.models import MedicationPlan, MedicationPlanVersion
from app.models import Patient

RIYADH = ZoneInfo("Asia/Riyadh")


def normalize_medication_name(value: str) -> str:
    """Return a conservative comparison key without changing display text."""
    normalized = unicodedata.normalize("NFKC", value)
    return " ".join(normalized.casefold().split())


class MedicationPlanService:
    """Create immutable revisions while locking their patient and plan."""

    def __init__(self, session: Session, now):
        self.session = session
        self.now = now

    def create(
        self,
        circle_id: UUID,
        actor_id: UUID,
        body: PlanRequest,
    ) -> MedicationPlan:
        patient = self._patient(circle_id, lock=True)
        normalized_name = normalize_medication_name(body.name)
        require_available_name(
            self.session,
            patient.id,
            normalized_name,
            body,
            effective_from_on=body.treatment_starts_on,
        )
        plan = MedicationPlan(
            patient_id=patient.id,
            created_by_account_id=actor_id,
        )
        self.session.add(plan)
        self.session.flush()
        add_plan_version(
            self.session,
            plan,
            actor_id,
            body,
            1,
            normalized_name,
            body.treatment_starts_on,
        )
        return plan

    def revise(
        self,
        circle_id: UUID,
        plan_id: UUID,
        actor_id: UUID,
        body: RevisePlanRequest,
    ) -> MedicationPlan:
        plan = self._plan(circle_id, plan_id)
        if plan.discontinued_at is not None:
            raise ValidationFailed(
                "A discontinued medication cannot be revised.",
                code="medication_discontinued",
            )
        current = self._current_version(plan.id)
        if current.version_number != body.expected_version_number:
            raise Conflict(code="medication_version_conflict")
        normalized_name = normalize_medication_name(body.name)
        effective_from_on = body.effective_from_on or (
            self.now.astimezone(RIYADH).date() + timedelta(days=1)
        )
        today = self.now.astimezone(RIYADH).date()
        if effective_from_on <= today:
            raise ValidationFailed(
                "A revision must start after today.",
                code="medication_revision_date",
            )
        if effective_from_on <= current.effective_from_on:
            raise ValidationFailed(
                "A revision must follow the current version.",
                code="medication_revision_date",
            )
        if (
            body.treatment_ends_on is not None
            and body.treatment_ends_on < effective_from_on
        ):
            raise ValidationFailed(
                "A revision cannot start after treatment ends.",
                code="medication_revision_date",
            )
        if same_definition(
            self.session, current, body, normalized_name
        ):
            return plan
        require_available_name(
            self.session,
            plan.patient_id,
            normalized_name,
            body,
            exclude_plan_id=plan.id,
            effective_from_on=effective_from_on,
        )
        current.effective_until_on = effective_from_on
        add_plan_version(
            self.session,
            plan,
            actor_id,
            body,
            current.version_number + 1,
            normalized_name,
            effective_from_on,
        )
        return plan

    def discontinue(
        self,
        circle_id: UUID,
        plan_id: UUID,
        actor_id: UUID,
    ) -> MedicationPlan:
        plan = self._plan(circle_id, plan_id)
        if plan.discontinued_at is not None:
            return plan
        plan.discontinued_at = self.now
        plan.discontinued_by_account_id = actor_id
        self.session.flush()
        return plan

    def _patient(self, circle_id: UUID, *, lock: bool) -> Patient:
        statement = select(Patient).where(
            Patient.care_circle_id == circle_id
        )
        if lock:
            statement = statement.with_for_update()
        patient = self.session.scalar(statement)
        if patient is None:
            raise NotFound("The patient does not exist.")
        return patient

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MedicationPlan:
        patient = self._patient(circle_id, lock=True)
        plan = self.session.scalar(
            select(MedicationPlan)
            .where(
                MedicationPlan.id == plan_id,
                MedicationPlan.patient_id == patient.id,
            )
            .with_for_update()
        )
        if plan is None:
            raise NotFound("The medication plan does not exist.")
        return plan

    def _current_version(self, plan_id: UUID) -> MedicationPlanVersion:
        version = self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan_id,
                MedicationPlanVersion.effective_until_on.is_(None),
            )
        )
        if version is None:
            raise Conflict(code="medication_has_no_current_version")
        return version
