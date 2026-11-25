"""Immutable medicine-plan versions: building one, comparing two, the key
two medicine names are compared by, and whether a name is free within a
treatment period."""

import unicodedata
from datetime import date, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import patient_zone
from app.errors import Conflict
from app.medications.inputs import PlanRequest
from app.models import (
    CareCircle,
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
    MedicationScheduleDay,
    MedicationScheduleMonthDay,
)


def normalize_medication_name(value: str) -> str:
    """Return a conservative comparison key without changing display text."""
    normalized = unicodedata.normalize("NFKC", value)
    return " ".join(normalized.casefold().split())


def add_plan_version(
    session: Session,
    plan: MedicationPlan,
    actor_id: UUID,
    body: PlanRequest,
    number: int,
    normalized_name: str,
    effective_from_on: date,
) -> MedicationPlanVersion:
    """Persist one complete plan version and its dose schedules."""
    # The version: the medicine's fields, from `effective_from_on` on, and who
    # made it.
    version = MedicationPlanVersion(
        medication_plan_id=plan.id,
        version_number=number,
        name=body.name,
        normalized_name=normalized_name,
        strength_value=body.strength_value,
        strength_unit=body.strength_unit,
        dosage_form=body.dosage_form,
        reason_for_use=body.reason_for_use,
        instructions=body.instructions,
        missed_after_minutes=body.missed_after_minutes,
        treatment_starts_on=body.treatment_starts_on,
        treatment_ends_on=body.treatment_ends_on,
        effective_from_on=effective_from_on,
        created_by_account_id=actor_id,
    )
    session.add(version)
    session.flush()
    # Each dose time, then its weekdays and its days of the month (an interval
    # dose keeps its number of days on the dose time itself).
    for item in body.schedules:
        schedule = MedicationSchedule(
            plan_version_id=version.id,
            time_of_day=item.time_of_day,
            dose_value=item.dose_value,
            dose_unit=item.dose_unit,
            instructions=item.instructions,
            repeat=item.repeat,
            interval_days=item.interval_days,
        )
        session.add(schedule)
        session.flush()
        session.add_all(
            MedicationScheduleDay(
                schedule_id=schedule.id,
                weekday=weekday,
            )
            for weekday in sorted(item.weekdays)
        )
        session.add_all(
            MedicationScheduleMonthDay(
                schedule_id=schedule.id,
                month_day=month_day,
            )
            for month_day in sorted(item.month_days)
        )
    session.flush()
    return version


def require_available_name(
    session: Session,
    patient: CareCircle,
    normalized_name: str,
    body: PlanRequest,
    *,
    exclude_plan_id: UUID | None = None,
    effective_from_on: date | None = None,
) -> None:
    """Reject overlapping current treatments with the same name.

    A stopped plan ends on the day it was stopped in the patient's
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
            MedicationPlan.care_circle_id == patient.id,
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
                    plan.stopped_at.astimezone(zone).date()
                    + timedelta(days=1)
                    if plan.stopped_at is not None
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
