"""User endpoints.

    PUT /api/v1/users/me/profile   save the first name, last name and display name

The profile page comes right after the first sign-in. The user is the one that
the access token belongs to; there is no user id in the URL, so nobody can write
another user's profile.
"""

import unicodedata
from typing import Annotated

from flask import Blueprint, jsonify
from pydantic import AfterValidator, Field
from pydantic_core import PydanticCustomError

from app.auth.decorators import current_auth, require_auth
from app.errors import NotFound
from app.extensions import get_user_store
from app.validation import Dto, parse_json_body

bp = Blueprint("users", __name__, url_prefix="/api/v1/users")


def _one_line(value: str) -> str:
    # A name is one line of text. A line break or another control character
    # would break the screens that show it.
    if any(unicodedata.category(ch) == "Cc" for ch in value):
        raise PydanticCustomError(
            "invalid_name", "A name cannot contain line breaks or control characters."
        )
    return value


def _name(max_length: int):
    # The Dto base class already removes spaces at both ends, so a value of only
    # spaces becomes empty and is refused by min_length.
    return Annotated[
        str, Field(min_length=1, max_length=max_length), AfterValidator(_one_line)
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
        current_auth().user_id, body.first_name, body.last_name, body.display_name
    )
    if user is None:
        raise NotFound("This user does not exist.", code="user_not_found")
    return jsonify(user=user.to_dict())
