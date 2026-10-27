"""Save the authenticated account's first, last, and display names."""

import unicodedata
from typing import Annotated
from uuid import UUID

from flask import Blueprint, current_app, jsonify
from pydantic import AfterValidator, Field
from pydantic_core import PydanticCustomError
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.circles.inputs import DeleteAccountInput
from app.circles.support import care_work
from app.database import transaction
from app.errors import NotFound
from app.extensions import get_user_store
from app.models import Patient
from app.validation import Dto, parse_json_body, parse_optional_json_body

bp = Blueprint("users", __name__, url_prefix="/api/v1/accounts")


def _one_line(value: str) -> str:
    # Control characters are invalid in displayed names.
    if any(unicodedata.category(ch) == "Cc" for ch in value):
        raise PydanticCustomError(
            "invalid_name",
            "A name cannot contain line breaks or control characters.",
        )
    return value


def _name(max_length: int):
    # DTO normalization removes surrounding whitespace before validation.
    return Annotated[
        str,
        Field(min_length=1, max_length=max_length),
        AfterValidator(_one_line),
    ]


class ProfileRequest(Dto):
    first_name: _name(50)
    last_name: _name(50)
    display_name: _name(30)


@bp.put("/me/profile")
@require_auth
def save_profile():
    body = parse_json_body(ProfileRequest)
    user = get_user_store().update_profile(
        current_auth().user_id,
        body.first_name,
        body.last_name,
        body.display_name,
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
    # The app asks this before it shows the pages that create a circle for
    # your own care, so nobody fills them in for nothing.
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
      - patient_choice "delete" deletes the circle you are the patient of;
        "continue" keeps it, with the managers, under your name as text.
        It is required when you are a patient.
      - delete_last_managed_circles true also deletes circles where you are
        the only manager. Without it, such a circle blocks the deletion.
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
