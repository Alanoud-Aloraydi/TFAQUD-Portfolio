"""One error format for the whole API.

Every error response has this shape:

    {
      "error": {
        "code": "validation_error",       <- stable, for the app to act on
        "message": "The request is not valid.",
        "request_id": "3f2a...",
        "details": [{"field": "...", "code": "...", "message": "..."}],
        "retry_after_seconds": 120
      }
    }

When `retry_after_seconds` is present, the same number is sent in the standard
`Retry-After` header.

The Flutter app decides what to do from `code` (and shows its own Arabic text).
`message` is English and is not meant for the end user."""

from app.errors.api_errors import (
    ApiError,
    BadRequest,
    Conflict,
    Forbidden,
    NotFound,
    ServiceUnavailable,
    TooManyRequests,
    Unauthorized,
    ValidationFailed,
)
from app.errors.handlers import register_error_handlers
from app.errors.response import error_response

__all__ = [
    "ApiError",
    "BadRequest",
    "Conflict",
    "Forbidden",
    "NotFound",
    "ServiceUnavailable",
    "TooManyRequests",
    "Unauthorized",
    "ValidationFailed",
    "error_response",
    "register_error_handlers",
]
