"""What a care circle is called, and for whom.

- A patient with an account names their own circle: when they make it for
  themself, or when they complete a request someone sent them («رعايتي»,
  «صحتي», «دائرتي» or a name they type). Only they see that name.
- Everyone else sees «دائرة» and the patient's display name, so a personal
  choice such as «صحتي» is never shown to the others.
- A patient without an account (no phone number) names nothing: everyone
  sees «دائرة» and the patient's first name.

The name of the others is worked out when it is read, so a new display name
or a corrected first name shows at once. `care_circle.name` keeps the
patient's own choice; for a patient without an account it holds the same
automatic name, which nobody reads back.
"""

from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Account, CareCircle, Patient

SHARED_PREFIX = "دائرة"

# The patient's own name when an older app completes a request without one.
OWN_NAME_DEFAULT = "دائرتي"


def shared_name(person_name: str | None) -> str:
    """«دائرة» and the name, as everyone but the patient sees the circle."""
    name = (person_name or "").strip()
    return f"{SHARED_PREFIX} {name}" if name else SHARED_PREFIX


def account_name(account: Account | None) -> str | None:
    """The name an account shows to others: its display name, else its
    first name."""
    if account is None:
        return None
    return account.display_name or account.first_name


def name_for(
    viewer: UUID,
    *,
    own_name: str,
    patient_account_id: UUID | None,
    patient_account_name: str | None,
    patient_first_name: str | None,
) -> str:
    """The circle's name as `viewer` sees it."""
    if patient_account_id is None:
        return shared_name(patient_first_name)
    if patient_account_id == viewer:
        return own_name
    return shared_name(patient_account_name)


def circle_name(session: Session, circle_id: UUID, viewer: UUID) -> str:
    """Read one circle's name for `viewer`."""
    row = session.execute(
        select(
            CareCircle.name,
            Patient.account_id,
            Patient.first_name,
            Account.display_name,
            Account.first_name.label("account_first_name"),
        )
        .join(Patient, Patient.care_circle_id == CareCircle.id)
        .outerjoin(Account, Account.id == Patient.account_id)
        .where(CareCircle.id == circle_id)
    ).one_or_none()
    if row is None:
        return ""
    return name_for(
        viewer,
        own_name=row.name,
        patient_account_id=row.account_id,
        patient_account_name=row.display_name or row.account_first_name,
        patient_first_name=row.first_name,
    )
