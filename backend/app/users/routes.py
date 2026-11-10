"""HTTP endpoints of the signed-in account: /api/v1/accounts/me.

Flow: the app's ProfileRemoteDataSource -> PUT /me/profile (save_profile)
-> UserStore.update_profile -> the ``account`` table.
"""

import unicodedata
from typing import Annotated
from uuid import UUID

from flask import Blueprint, current_app, jsonify
from pydantic import AfterValidator, Field
from pydantic_core import PydanticCustomError
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.circles.inputs import City, DeleteAccountInput, IsoDate
from app.circles.support import care_work
from app.clock import latest_today
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock, get_user_store
from app.models import Account, Patient
from app.validation import Dto, parse_json_body, parse_optional_json_body

bp = Blueprint("users", __name__, url_prefix="/api/v1/accounts")


def _one_line(value: str) -> str:
    """Refuse a name with a line break or another control character."""
    if any(unicodedata.category(ch) == "Cc" for ch in value):
        raise PydanticCustomError(
            "invalid_name",
            "A name cannot contain line breaks or control characters.",
        )
    return value


def _name(max_length: int):
    """A required one-line name of 1 to ``max_length`` characters.

    Length is counted in code points after trimming (Dto strips the
    surrounding whitespace first), as the ``account`` table's
    ``profile_names`` check counts it. The app limits its fields the same
    way (NameLimits, CodePointLengthFormatter).
    """
    return Annotated[
        str,
        Field(min_length=1, max_length=max_length),
        AfterValidator(_one_line),
    ]


class ProfileRequest(Dto):
    """Body of PUT /api/v1/accounts/me/profile."""

    first_name: _name(50)
    last_name: _name(50)
    display_name: _name(30)
    # Onboarding sends both; the account page sends neither, and then the
    # saved values stay.
    birth_date: IsoDate | None = None
    city: City | None = None


@bp.put("/me/profile")
@require_auth
def save_profile():
    """Save the signed-in account's names, and birth date and city if sent.

    Called by onboarding (all five fields) and the account page (names
    only). A birth date in the future is refused with
    ``invalid_birth_date``. Returns the saved account.
    """
    body = parse_json_body(ProfileRequest)
    # No patient, so no zone yet: only a day that is still ahead
    # everywhere is in the future. A circle checks it again in the
    # patient's own zone (`CareService`).
    if body.birth_date and body.birth_date > latest_today(get_clock().now()):
        raise ValidationFailed(
            "The birth date cannot be in the future.",
            code="invalid_birth_date",
        )
    user = get_user_store().update_profile(
        current_auth().user_id,
        body.first_name,
        body.last_name,
        body.display_name,
        birth_date=body.birth_date,
        city=body.city,
    )
    if user is None:
        raise NotFound("This user does not exist.", code="user_not_found")
    return jsonify(account=user.to_dict())


@bp.get("/me")
@require_auth
def read_account():
    """The signed-in account, as the account page needs it."""
    user = get_user_store().get(current_auth().user_id)
    if user is None:
        raise NotFound("This user does not exist.", code="user_not_found")
    account = user.to_dict()
    if "sqlalchemy" in current_app.extensions:
        with transaction() as session:
            stored = session.get(Account, UUID(user.id))
            account["avatar_code"] = stored.avatar_code if stored else None
    else:
        account["avatar_code"] = None
    # The app asks this before it shows the pages that create a circle for
    # the person's own care, so nobody fills them in for nothing.
    account["patient_circle_id"] = _patient_circle_id(user.id)
    response = jsonify(account=account)
    response.headers["Cache-Control"] = "no-store"
    return response


def _patient_circle_id(account_id: str) -> str | None:
    """The circle this account receives care in, or None.

    An account is the patient of at most one circle, so the answer is one id.
    """
    if "sqlalchemy" not in current_app.extensions:
        return None  # The in-memory mode of the unit tests has no circles.
    with transaction() as session:
        circle_id = session.scalar(
            select(Patient.care_circle_id).where(
                Patient.account_id == UUID(account_id)
            )
        )
    return None if circle_id is None else str(circle_id)


@bp.delete("/me")
@require_auth
def delete_account():
    """Delete the account and end every sign-in of it.

    What happens to the account's care is decided by the body:
      - patient_choice "delete" deletes the circle the account is the
        patient of; "continue" keeps it, with the managers, under the
        account's name as text. It is required when the account is a
        patient.
      - delete_last_managed_circles true also deletes circles where the
        account is the only manager. Without it, such a circle blocks the
        deletion.
    An account with no circles can send no body.
    """
    body = parse_optional_json_body(DeleteAccountInput)
    with care_work() as work:
        work.care.delete_account(
            work.actor,
            patient_choice=body.patient_choice,
            delete_last_managed_circles=body.delete_last_managed_circles,
        )
    return "", 204
