"""Medication-name availability within treatment periods."""

from datetime import date, timedelta
from uuid import UUID
from zoneinfo import ZoneInfo

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.errors import Conflict
from app.medications.inputs import PlanRequest
from app.models import MedicationPlan, MedicationPlanVersion

RIYADH = ZoneInfo("Asia/Riyadh")


def require_available_name(
    session: Session,
    patient_id: UUID,
    normalized_name: str,
    body: PlanRequest,
    *,
    exclude_plan_id: UUID | None = None,
    effective_from_on: date | None = None,
) -> None:
    """Reject overlapping current treatments with the same name."""
    candidate_start = max(
        body.treatment_starts_on,
        effective_from_on or body.treatment_starts_on,
    )
    candidate_end = (
        body.treatment_ends_on + timedelta(days=1)
        if body.treatment_ends_on is not None
        else None
    )
    statement = (
        select(MedicationPlan, MedicationPlanVersion)
        .join(
            MedicationPlanVersion,
            MedicationPlanVersion.medication_plan_id == MedicationPlan.id,
        )
        .where(
            MedicationPlan.patient_id == patient_id,
            MedicationPlanVersion.normalized_name == normalized_name,
        )
    )
    if exclude_plan_id is not None:
        statement = statement.where(MedicationPlan.id != exclude_plan_id)
    for plan, version in session.execute(statement):
        existing_start = max(
            version.treatment_starts_on,
            version.effective_from_on,
        )
        ends = [
            value
            for value in (
                (
                    version.treatment_ends_on + timedelta(days=1)
                    if version.treatment_ends_on is not None
                    else None
                ),
                version.effective_until_on,
                (
                    plan.discontinued_at.astimezone(RIYADH).date()
                    + timedelta(days=1)
                    if plan.discontinued_at is not None
                    else None
                ),
            )
            if value is not None
        ]
        existing_end = min(ends) if ends else None
        if existing_end is not None and existing_start >= existing_end:
            continue
        if (
            existing_end is None or candidate_start < existing_end
        ) and (
            candidate_end is None or existing_start < candidate_end
        ):
            raise Conflict(code="medication_period_conflict")
