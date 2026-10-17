"""Request validation.

Each endpoint that reads a JSON body describes it with a small class (a DTO)
and calls `parse_json_body(TheClass)`. The check happens on the server, before
any business logic runs, so the app's own checks are never the only ones.

Rules that apply to every DTO:
  - unknown fields are rejected (a typo is an error, not silently ignored);
  - text fields are stripped of leading and trailing spaces.

The error never echoes the value that was sent. A phone number or a code must
not end up in a response or a log by accident.
"""

from typing import TypeVar

from flask import request
from pydantic import BaseModel, ConfigDict, ValidationError

from app.errors import BadRequest, ValidationFailed


class Dto(BaseModel):
    """Base class for request bodies."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


T = TypeVar("T", bound=Dto)


def parse_json_body(model: type[T]) -> T:
    data = request.get_json(silent=True)
    if data is None:
        raise BadRequest(
            "The request body must be valid JSON with the header "
            "'Content-Type: application/json'.",
            code="invalid_json",
        )
    try:
        return model.model_validate(data)
    except ValidationError as exc:
        details = [
            {
                "field": ".".join(str(part) for part in err["loc"]) or "body",
                "code": err["type"],
                "message": err["msg"],
            }
            for err in exc.errors()
        ]
        raise ValidationFailed(details=details) from exc
