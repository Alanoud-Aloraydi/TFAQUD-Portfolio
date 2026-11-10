"""Medication-name availability within treatment periods."""

from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import patient_zone
from app.errors import Conflict
from app.medications.inputs import PlanRequest
from app.models import MedicationPlan, MedicationPlanVersion, Patient


def require_available_name(
    session: Session,
    patient: Patient,
    normalized_name: str,
    body: PlanRequest,
    *,
    exclude_plan_id: UUID | None = None,
    effective_from_on: date | None = None,
) -> None:
    """Reject overlapping current treatments with the same name.

    A discontinued plan ends on the day it was stopped in the patient's
    own zone."""
    # The days the new or edited medicine would run: from its start (or its
    # edit's start) to the day after its end, or open-ended.
    zone = patient_zone(patient)
    candidate_start = max(
        body.treatment_starts_on,
        effective_from_on or body.treatment_starts_on,
    )
    candidate_end = (
        body.treatment_ends_on + timedelta(days=1)
        if body.treatment_ends_on is not None
        else None
    )
    # The patient's other medicines under the same name (cancelled versions do
    # not count).
    statement = (
        select(MedicationPlan, MedicationPlanVersion)
        .join(
            MedicationPlanVersion,
            MedicationPlanVersion.medication_plan_id == MedicationPlan.id,
        )
        .where(
            MedicationPlan.patient_id == patient.id,
            MedicationPlanVersion.normalized_name == normalized_name,
            MedicationPlanVersion.cancelled_at.is_(None),
        )
    )
    if exclude_plan_id is not None:
        statement = statement.where(MedicationPlan.id != exclude_plan_id)
    for plan, version in session.execute(statement):
        # Each one runs from its start to the first of its end, its version's
        # end and its stop; one that ends before it starts runs on no day.
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
                    plan.discontinued_at.astimezone(zone).date()
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
        # Two runs of days that meet are a conflict.
        if (
            existing_end is None or candidate_start < existing_end
        ) and (
            candidate_end is None or existing_start < candidate_end
        ):
            raise Conflict(code="medication_period_conflict")
