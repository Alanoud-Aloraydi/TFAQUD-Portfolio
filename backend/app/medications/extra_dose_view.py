"""One extra dose of «سجّل جرعة الآن» as the app reads it."""

from sqlalchemy.orm import Session

from app.accounts import recorder_response
from app.medications.representations import plain_number
from app.models import Account, MedicationExtraDose


def extra_dose_response(session: Session, dose: MedicationExtraDose) -> dict:
    """The dose, with who recorded it (null when their account was
    deleted)."""
    recorder = (
        session.get(Account, dose.recorded_by_account_id)
        if dose.recorded_by_account_id
        else None
    )
    return {
        "id": str(dose.id),
        "plan_id": str(dose.medication_plan_id),
        "taken_at": dose.taken_at.isoformat(),
        "dose_value": plain_number(dose.dose_value),
        "dose_unit": dose.dose_unit,
        "recorded_at": dose.recorded_at.isoformat(),
        "recorded_by": recorder_response(recorder),
    }
