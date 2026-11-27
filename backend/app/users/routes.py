"""The signed-in account's endpoints under /api/v1/accounts/me: read it,
save its profile, or delete it."""

import unicodedata
from typing import Annotated
from uuid import UUID

from flask import Blueprint, current_app, jsonify
from pydantic import AfterValidator, Field, model_validator
from pydantic_core import PydanticCustomError
from sqlalchemy import select

from app.auth.decorators import current_auth, require_auth
from app.circles.inputs import City, DeleteAccountInput, IsoDate, TimeZone
from app.circles.support import care_work
from app.clock import is_zone, latest_today, require_old_enough
from app.database import transaction
from app.errors import NotFound, ValidationFailed
from app.extensions import get_clock, get_user_store
from app.models import Account, CareCircle
from app.validation import Dto, parse_json_body, parse_optional_json_body


bp = Blueprint("users", __name__, url_prefix="/api/v1/accounts")


def _one_line(value: str) -> str:
    """Refuse a name with a line break or another control character."""
    # Control characters are invalid in displayed names.
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
    """The body of PUT /api/v1/accounts/me/profile."""

    first_name: _name(50)
    last_name: _name(50)
    display_name: _name(30)
    # Onboarding sends both; the account page sends the city alone. One
    # left out keeps the saved value.
    birth_date: IsoDate | None = None
    city: City | None = None
    # The city's IANA zone, sent with it: the zone of the circle the
    # account is the patient of, if any (`UserStore.update_profile`).
    time_zone: TimeZone | None = None

    @model_validator(mode="after")
    def _zone_with_city(self):
        """A zone is the city's, so it comes only with one."""
        if self.time_zone is not None and self.city is None:
            raise ValueError("Send the time zone with the city.")
        return self


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
            select(CareCircle.id).where(
                CareCircle.account_id == UUID(account_id)
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


@bp.put("/me/profile")
@require_auth
def save_profile():
    """Save the signed-in account's names, and birth date, city and zone if
    sent.

    Called by onboarding (names, birth date and city) and the account page
    (names, city and zone). A birth date in the future is refused with
    ``invalid_birth_date``, a zone that is not an IANA zone with
    ``invalid_time_zone``. Returns the saved account.
    """
    # A birth date in the future is refused; then the account's profile is
    # saved.
    body = parse_json_body(ProfileRequest)
    # No patient, so no zone yet: only a day that is still ahead
    # everywhere is in the future. A circle checks it again in the
    # patient's own zone (`CareService`).
    today = latest_today(get_clock().now())
    if body.birth_date and body.birth_date > today:
        raise ValidationFailed(
            "The birth date cannot be in the future.",
            code="invalid_birth_date",
        )
    if body.birth_date:
        require_old_enough(body.birth_date, today)
    if body.time_zone is not None and not is_zone(body.time_zone):
        raise ValidationFailed(
            "The time zone is not a known IANA zone.",
            code="invalid_time_zone",
        )
    user = get_user_store().update_profile(
        current_auth().user_id,
        body.first_name,
        body.last_name,
        body.display_name,
        birth_date=body.birth_date,
        city=body.city,
        time_zone=body.time_zone,
    )
    if user is None:
        raise NotFound("This user does not exist.", code="user_not_found")
    return jsonify(account=user.to_dict())
