"""The medical profile and the emergency card."""

from sqlalchemy.orm import Session

from app.circles.views.contacts import contact_views
from app.medical import MedicalProfile
from app.models import Account, CareCircle, EmergencyContact


def medical_view(profile: MedicalProfile) -> dict:
    """The medical profile, as the app reads it."""
    return {
        "blood_type": profile.blood_type,
        "conditions": profile.conditions,
        "allergies": profile.allergies,
    }


def emergency_card_view(
    session: Session,
    patient: CareCircle,
    profile: MedicalProfile,
    contacts: list[EmergencyContact],
) -> dict:
    """The emergency card: only what a helper needs to read quickly.

    The card is shown to people who help in an emergency, so it carries no
    birth date, city or coordinates. Names come from the account while the
    patient is linked to one, like in `patient_view`.
    """
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        **medical_view(profile),
        "emergency_contacts": contact_views(session, contacts),
    }
