"""Adding a medicine to a circle."""

from uuid import UUID

from sqlalchemy import select

from app.clock import patient_today
from app.errors import NotFound, ValidationFailed
from app.medications.availability import require_available_name
from app.medications.inputs import PlanRequest
from app.medications.plan_versions import add_plan_version
from app.medications.plans.names import normalize_medication_name
from app.models import CareCircle, MedicationPlan


class PlanCreation:
    """Adds a medicine."""

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
