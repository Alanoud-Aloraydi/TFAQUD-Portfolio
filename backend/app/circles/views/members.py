"""The members as the circle page shows them."""

from sqlalchemy import select

from app.circles.leader import AREAS, edit_access
from app.models import Account, CareCircleManager


def member_view(
    membership, name, avatar_code, phone_number, *, viewer, leader,
    patient_account,
) -> dict:
    """One member as the circle page shows them."""
    account_id = membership.account_id
    access = edit_access(membership, account_id == leader)
    edits = any(access.values())
    return {
        "account_id": str(account_id),
        "display_name": name,
        "is_you": account_id == viewer,
        "is_patient": account_id == patient_account,
        # The one who removes members and says who edits what.
        "is_leader": account_id == leader,
        "role": "manager" if edits else "member",
        # Each area this member may edit; `can_edit` (any of them) for
        # the app before the areas.
        "edit_access": access,
        "can_edit": edits,
        # Already the account's own avatar; a patient who manages their
        # own circle shares it, like their photo.
        "avatar_code": avatar_code,
        # So any circle member can call another, the same as an
        # emergency contact's number.
        "phone_number": phone_number,
    }


def circle_members(
    session, circle_id, viewer, leader, patient_account
) -> list:
    """The circle's members: the patient, you, the leader, then by name."""
    rows = session.execute(
        select(CareCircleManager, Account.display_name,
               Account.avatar_code, Account.phone_number)
        .join(Account, Account.id == CareCircleManager.account_id)
        .where(CareCircleManager.care_circle_id == circle_id)
    ).all()
    rows.sort(key=lambda row: (row[0].account_id != patient_account,
                               row[0].account_id != viewer,
                               row[0].account_id != leader, row[1] or "",
                               str(row[0].account_id)))
    return [
        member_view(
            *row, viewer=viewer, leader=leader,
            patient_account=patient_account,
        )
        for row in rows
    ]


def patient_member(patient, linked, viewer) -> dict:
    """The patient with an account who is not a member, shown first."""
    patient_account = patient.account_id
    patient_name = (
        f"{linked.first_name} {linked.last_name}" if linked
        else f"{patient.first_name} {patient.last_name}"
    )
    return {
        "account_id": str(patient_account) if patient_account else None,
        "display_name": patient_name.strip(),
        "is_you": patient_account == viewer,
        "is_patient": True,
        "is_leader": False,
        "role": "patient",
        "edit_access": {area: False for area in AREAS},
        "can_edit": False,
        "avatar_code": linked.avatar_code if linked else patient.avatar_code,
        "phone_number": linked.phone_number if linked else None,
    }
