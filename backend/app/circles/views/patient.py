"""The patient as the circle page shows them."""

from uuid import UUID

from sqlalchemy.orm import Session

from app.models import Account, CareCircle


def patient_view(session: Session, patient: CareCircle, viewer: UUID) -> dict:
    """Basic data of the patient. Names and avatar come from the account
    while linked: one person, one picture, like their photo."""
    # A patient with an account shows the account's names and picture; one
    # without shows the circle's.
    linked = (
        session.get(Account, patient.account_id)
        if patient.account_id
        else None
    )
    source = linked if linked else patient
    return {
        "first_name": source.first_name,
        "last_name": source.last_name,
        "birth_date": source.birth_date.isoformat(),
        "city": source.city,
        # Every time of the circle is wall clock in this IANA zone.
        "time_zone": patient.time_zone,
        "latitude": patient.latitude,
        "longitude": patient.longitude,
        "has_account": linked is not None,
        "app_mode": linked.app_mode if linked else None,
        "is_you": linked is not None and linked.id == viewer,
        "avatar_code": source.avatar_code,
    }
