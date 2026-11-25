"""The medical profile, the emergency contacts and the emergency card, as
the app reads them."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import recorder_response
from app.medical import MedicalProfile
from app.models import Account, CareCircle, CareCircleManager, EmergencyContact


def contact_views(
    session: Session, contacts: list[EmergencyContact]
) -> list[dict]:
    """Emergency contacts, as the app reads them.

    A contact whose number is a TFAQUD account's is «متحقق» (`verified`).
    Its name and avatar (`account`) are shown only when that account is in
    the patient's circle, whose members see each other already; for anyone
    else only the mark is shown.
    """
    phones = {contact.phone_number for contact in contacts}
    accounts = {
        account.phone_number: account
        for account in (
            session.scalars(
                select(Account).where(Account.phone_number.in_(phones))
            )
            if phones else ()
        )
    }
    # The circle's members and its patient's own account.
    circles = {contact.care_circle_id for contact in contacts}
    known = set()
    if circles:
        known.update(session.scalars(
            select(CareCircleManager.account_id).where(
                CareCircleManager.care_circle_id.in_(circles)
            )
        ))
        known.update(session.scalars(
            select(CareCircle.account_id).where(
                CareCircle.id.in_(circles),
                CareCircle.account_id.is_not(None),
            )
        ))
    return [
        one_contact_view(contact, accounts.get(contact.phone_number), known)
        for contact in contacts
    ]


def contact_view(session: Session, contact: EmergencyContact) -> dict:
    """One emergency contact, as `contact_views` reads it."""
    return contact_views(session, [contact])[0]


def one_contact_view(
    contact: EmergencyContact, account: Account | None, known: set
) -> dict:
    return {
        "id": str(contact.id),
        "name": contact.name,
        "relation": contact.relation,
        "relation_other": contact.relation_other,
        "phone_number": contact.phone_number,
        "verified": account is not None,
        "account": (
            recorder_response(account)
            if account is not None and account.id in known
            else None
        ),
    }


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
