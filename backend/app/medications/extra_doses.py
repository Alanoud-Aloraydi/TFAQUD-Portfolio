"""«سجّل جرعة الآن»: recording an extra dose, and the extra doses taken in
some days."""

from datetime import date, time, timedelta
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import as_utc, local_moment, patient_zone
from app.errors import NotFound, ValidationFailed
from app.medications.dose_inputs import ExtraDoseRequest
from app.medications.doses import doses_kept_from
from app.medications.inputs import UNIT_BY_FORM
from app.medications.views import extra_dose_response
from app.models import (
    CareCircle,
    MedicationExtraDose,
    MedicationPlan,
    MedicationPlanVersion,
)


class MedicationExtraDoses:
    """Extra doses: always on top of the scheduled ones, never one of them."""

    def __init__(self, session: Session, now):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    def record(
        self, circle_id: UUID, actor_id: UUID, body: ExtraDoseRequest
    ) -> MedicationExtraDose:
        """Record one dose of a medicine of this circle that is still taken,
        at a past time, in a unit its form is measured in."""
        plan = self.session.scalar(
            select(MedicationPlan).where(
                MedicationPlan.id == body.plan_id,
                MedicationPlan.care_circle_id == circle_id,
            )
        )
        if plan is None:
            raise NotFound("The medication plan does not exist.")
        if plan.stopped_at is not None:
            raise ValidationFailed(
                "A stopped medicine takes no dose.", code="medication_stopped"
            )
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
        if body.taken_at < doses_kept_from(self.now):
            raise ValidationFailed(
                "Doses past three months are deleted.", code="dose_too_old"
            )
        units = UNIT_BY_FORM[self._dosage_form(plan.id)]
        units = {units} if isinstance(units, str) else units
        if body.dose_unit not in units:
            raise ValidationFailed(
                "Dose unit does not match the dosage form.",
                code="dose_unit_mismatch",
            )
        dose = MedicationExtraDose(
            medication_plan_id=plan.id,
            taken_at=as_utc(body.taken_at),
            dose_value=body.dose_value,
            dose_unit=body.dose_unit,
            recorded_by_account_id=actor_id,
            recorded_at=self.now,
        )
        self.session.add(dose)
        self.session.flush()
        return dose

    def _dosage_form(self, plan_id: UUID) -> str:
        """The form of the newest version that was not cancelled."""
        return self.session.scalar(
            select(MedicationPlanVersion.dosage_form)
            .where(
                MedicationPlanVersion.medication_plan_id == plan_id,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
            .order_by(MedicationPlanVersion.version_number.desc())
            .limit(1)
        )


def extra_doses_between(
    session: Session,
    circle_id: UUID,
    first: date,
    last: date,
    plan_id: UUID | None = None,
) -> list[dict]:
    """The extra doses taken from `first` to `last`, days of the patient's
    own clock, newest first, optionally of one medicine."""
    patient = session.get(CareCircle, circle_id)
    if patient is None:
        raise NotFound("The care circle does not exist.")
    zone = patient_zone(patient)
    query = (
        select(MedicationExtraDose)
        .join(MedicationPlan)
        .where(
            MedicationPlan.care_circle_id == circle_id,
            MedicationExtraDose.taken_at >= local_moment(first, time(0), zone),
            MedicationExtraDose.taken_at
            < local_moment(last + timedelta(days=1), time(0), zone),
        )
        .order_by(MedicationExtraDose.taken_at.desc())
    )
    if plan_id is not None:
        query = query.where(MedicationExtraDose.medication_plan_id == plan_id)
    return [
        extra_dose_response(session, dose) for dose in session.scalars(query)
    ]
