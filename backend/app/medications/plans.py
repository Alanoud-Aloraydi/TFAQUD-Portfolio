"""Transactional commands for versioned medication plans."""

import unicodedata
from datetime import timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.errors import Conflict, NotFound, ValidationFailed
from app.medications.availability import require_available_name
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plan_versions import add_plan_version
from app.medications.plan_versions import same_definition
from app.models import MedicationDoseRecord, MedicationPlan
from app.models import MedicationPlanVersion, MedicationSchedule, Patient

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
        if body.treatment_starts_on < self.now.astimezone(RIYADH).date():
            raise ValidationFailed(code="medication_start_in_past")
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
        today = self.now.astimezone(RIYADH).date()
        if current.effective_from_on > today:
            raise Conflict(code="medication_pending_revision")
        normalized_name = normalize_medication_name(body.name)
        if same_definition(
            self.session, current, body, normalized_name
        ):
            return plan
        effective_from_on = body.effective_from_on or today
        if effective_from_on < today:
            raise ValidationFailed(
                "A revision cannot start in the past.",
                code="medication_revision_date",
            )
        # The current version began today (the medicine was added or edited
        # today) and the edit is for today too: it replaces that version.
        # Days are the unit of a version, so two cannot start the same day.
        replaces_today = effective_from_on == current.effective_from_on
        if replaces_today and self._has_doses(current):
            # A dose of today was already recorded under it. That dose keeps
            # the plan it was given under: the edit starts tomorrow.
            effective_from_on = today + timedelta(days=1)
            replaces_today = False
        if (
            not replaces_today
            and effective_from_on <= current.effective_from_on
        ):
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
        require_available_name(
            self.session,
            plan.patient_id,
            normalized_name,
            body,
            exclude_plan_id=plan.id,
            effective_from_on=effective_from_on,
        )
        if replaces_today:
            # Kept, cancelled, for the audit, like a cancelled future edit.
            current.cancelled_at = self.now
            self.session.flush()
        else:
            current.effective_until_on = effective_from_on
        next_number = self.session.scalar(
            select(func.max(MedicationPlanVersion.version_number)).where(
                MedicationPlanVersion.medication_plan_id == plan.id
            )
        ) + 1
        add_plan_version(
            self.session,
            plan,
            actor_id,
            body,
            next_number,
            normalized_name,
            effective_from_on,
        )
        return plan

    def cancel_pending(
        self,
        circle_id: UUID,
        plan_id: UUID,
        expected_version_number: int,
    ) -> MedicationPlan:
        """Cancel a future revision while retaining its audit version."""
        plan = self._plan(circle_id, plan_id)
        if plan.discontinued_at is not None:
            raise Conflict(code="medication_discontinued")
        pending = self._current_version(plan.id)
        today = self.now.astimezone(RIYADH).date()
        if (pending.version_number != expected_version_number
                or pending.effective_from_on <= today):
            raise Conflict(code="medication_version_conflict")
        previous = self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan.id,
                MedicationPlanVersion.effective_until_on
                == pending.effective_from_on,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
        if previous is None:
            raise Conflict(code="medication_version_conflict")
        pending.cancelled_at = self.now
        self.session.flush()
        previous.effective_until_on = None
        self.session.flush()
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

    def _has_doses(self, version: MedicationPlanVersion) -> bool:
        """Whether any dose was recorded under this version."""
        return self.session.scalar(
            select(MedicationDoseRecord.id)
            .join(
                MedicationSchedule,
                MedicationSchedule.id == MedicationDoseRecord.schedule_id,
            )
            .where(MedicationSchedule.plan_version_id == version.id)
            .limit(1)
        ) is not None

    def _current_version(self, plan_id: UUID) -> MedicationPlanVersion:
        version = self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan_id,
                MedicationPlanVersion.effective_until_on.is_(None),
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
        if version is None:
            raise Conflict(code="medication_has_no_current_version")
        return version
