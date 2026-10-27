"""Medication-name availability within treatment periods."""

from uuid import UUID

from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.errors import Conflict
from app.medications.inputs import PlanRequest
from app.models import MedicationPlan, MedicationPlanVersion


def require_available_name(
    session: Session,
    patient_id: UUID,
    normalized_name: str,
    body: PlanRequest,
    *,
    exclude_plan_id: UUID | None = None,
) -> None:
    """Reject overlapping current treatments with the same name."""
    statement = (
        select(MedicationPlan.id)
        .join(
            MedicationPlanVersion,
            MedicationPlanVersion.medication_plan_id == MedicationPlan.id,
        )
        .where(
            MedicationPlan.patient_id == patient_id,
            MedicationPlan.current_normalized_name == normalized_name,
            MedicationPlan.discontinued_at.is_(None),
            MedicationPlanVersion.effective_until.is_(None),
            or_(
                MedicationPlanVersion.treatment_ends_on.is_(None),
                MedicationPlanVersion.treatment_ends_on
                >= body.treatment_starts_on,
            ),
        )
    )
    if body.treatment_ends_on is not None:
        statement = statement.where(
            MedicationPlanVersion.treatment_starts_on
            <= body.treatment_ends_on
        )
    if exclude_plan_id is not None:
        statement = statement.where(MedicationPlan.id != exclude_plan_id)
    if session.scalar(statement) is not None:
        raise Conflict(code="medication_period_conflict")
