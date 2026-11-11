"""Transactional commands for versioned medication plans."""

import unicodedata
from datetime import timedelta
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.clock import patient_today
from app.errors import Conflict, NotFound, ValidationFailed
from app.medications.availability import require_available_name
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plan_versions import add_plan_version
from app.medications.plan_versions import same_definition
from app.models import MedicationDoseRecord, MedicationPlan
from app.models import MedicationPlanVersion, MedicationSchedule, CareCircle


def normalize_medication_name(value: str) -> str:
    """Return a conservative comparison key without changing display text."""
    normalized = unicodedata.normalize("NFKC", value)
    return " ".join(normalized.casefold().split())


class MedicationPlanService:
    """Create immutable revisions while locking their patient and plan."""

    def __init__(self, session: Session, now):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def create(
        self,
        circle_id: UUID,
        actor_id: UUID,
        body: PlanRequest,
    ) -> MedicationPlan:
        """Add a medicine to the circle's patient, starting today or later,
        with a name the patient has no other medicine under.
        """
        # Not in the past of the patient's own day; the patient is locked, and
        # has no other medicine of that name on the same days.
        patient = self._patient(circle_id, lock=True)
        if body.treatment_starts_on < patient_today(patient, self.now):
            raise ValidationFailed(code="medication_start_in_past")
        normalized_name = normalize_medication_name(body.name)
        require_available_name(
            self.session,
            patient,
            normalized_name,
            body,
            effective_from_on=body.treatment_starts_on,
        )
        # The medicine, and its first version from its start.
        plan = MedicationPlan(
            care_circle_id=patient.id,
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
        """Edit a medicine. A version that starts later is replaced. Otherwise
        the edit starts on the chosen day (today when none) and the current
        version ends then; an edit on the current version's own first day
        replaces it, or starts tomorrow when doses were already recorded.
        """
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None:
            raise ValidationFailed(
                "A stopped medication cannot be revised.",
                code="medication_stopped",
            )
        current = self._current_version(plan.id)
        if current.version_number != body.expected_version_number:
            raise Conflict(code="medication_version_conflict")
        today = patient_today(self._patient_of(plan), self.now)
        normalized_name = normalize_medication_name(body.name)
        if same_definition(
            self.session, current, body, normalized_name
        ):
            return plan
        if current.effective_from_on > today:
            # Not started yet, or an edit that starts later: this edit takes
            # its place, so a medicine can always be edited again. The one
            # replaced is kept, cancelled, for the audit, as cancel_pending
            # keeps it.
            previous = self._version_before(plan.id, current)
            current.cancelled_at = self.now
            self.session.flush()
            if previous is None:
                return self._start_again(
                    plan, actor_id, body, normalized_name, today
                )
            previous.effective_until_on = None
            self.session.flush()
            current = previous
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
            self._patient_of(plan),
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

    def _version_before(
        self, plan_id: UUID, version: MedicationPlanVersion
    ) -> MedicationPlanVersion | None:
        """The version in effect until [version] starts, or None when
        [version] is the first."""
        return self.session.scalar(
            select(MedicationPlanVersion).where(
                MedicationPlanVersion.medication_plan_id == plan_id,
                MedicationPlanVersion.effective_until_on
                == version.effective_from_on,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )

    def _start_again(
        self,
        plan: MedicationPlan,
        actor_id: UUID,
        body: RevisePlanRequest,
        normalized_name: str,
        today,
    ) -> MedicationPlan:
        """A medicine that has not started yet, edited: its new version
        starts when the treatment does, as a new medicine would."""
        # Like adding the medicine again: not in the past, and no other
        # medicine of that name on the same days.
        if body.treatment_starts_on < today:
            raise ValidationFailed(code="medication_start_in_past")
        require_available_name(
            self.session,
            self._patient_of(plan),
            normalized_name,
            body,
            exclude_plan_id=plan.id,
            effective_from_on=body.treatment_starts_on,
        )
        # The next version number counts every version, cancelled ones too.
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
            body.treatment_starts_on,
        )
        return plan

    def cancel_pending(
        self,
        circle_id: UUID,
        plan_id: UUID,
        expected_version_number: int,
    ) -> MedicationPlan:
        """Cancel a future revision while retaining its audit version."""
        # Only a medicine in use, whose version read by the app is the one
        # waiting to start.
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None:
            raise Conflict(code="medication_stopped")
        pending = self._current_version(plan.id)
        today = patient_today(self._patient_of(plan), self.now)
        if (pending.version_number != expected_version_number
                or pending.effective_from_on <= today):
            raise Conflict(code="medication_version_conflict")
        # Cancel it (it stays, for the history), and the version before goes on
        # with no end.
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

    def stop(
        self,
        circle_id: UUID,
        plan_id: UUID,
        actor_id: UUID,
    ) -> MedicationPlan:
        """Stop a medicine now, and say who stopped it; a medicine already
        stopped stays as it is.
        """
        plan = self._plan(circle_id, plan_id)
        if plan.stopped_at is not None:
            return plan
        plan.stopped_at = self.now
        plan.stopped_by_account_id = actor_id
        self.session.flush()
        return plan

    def _patient(self, circle_id: UUID, *, lock: bool) -> CareCircle:
        """The circle's patient, locked when `lock` (so two changes to their
        medicines run one after the other); 404 when there is none.
        """
        statement = select(CareCircle).where(
            CareCircle.id == circle_id
        )
        if lock:
            statement = statement.with_for_update()
        patient = self.session.scalar(statement)
        if patient is None:
            raise NotFound("The patient does not exist.")
        return patient

    def _patient_of(self, plan: MedicationPlan) -> CareCircle:
        """The plan's patient, already loaded and locked by `_plan`."""
        return self.session.get(CareCircle, plan.care_circle_id)

    def _plan(self, circle_id: UUID, plan_id: UUID) -> MedicationPlan:
        """The patient's medicine with this id, its patient row locked; 404 for
        a medicine of another patient.
        """
        patient = self._patient(circle_id, lock=True)
        plan = self.session.scalar(
            select(MedicationPlan)
            .where(
                MedicationPlan.id == plan_id,
                MedicationPlan.care_circle_id == patient.id,
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
        """The version in force: not ended, not cancelled."""
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
