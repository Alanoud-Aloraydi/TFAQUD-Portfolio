"""Save the authenticated account's first, last, and display names."""

import unicodedata
from typing import Annotated

from flask import Blueprint, jsonify
from pydantic import AfterValidator, Field
from pydantic_core import PydanticCustomError

from app.auth.decorators import current_auth, require_auth
from app.errors import NotFound
from app.extensions import get_user_store
from app.validation import Dto, parse_json_body

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
