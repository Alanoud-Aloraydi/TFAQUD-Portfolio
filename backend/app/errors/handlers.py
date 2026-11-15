"""Every error handler of the app: API errors, HTTP errors, database
failures and anything unexpected."""

from flask import Flask, current_app, g
from sqlalchemy.exc import DBAPIError, IntegrityError
from sqlalchemy.exc import TimeoutError as PoolTimeout
from werkzeug.exceptions import HTTPException

from app import metrics
from app.errors.api_errors import ApiError
from app.errors.database_handlers import (
    handle_database_conflict,
    handle_database_failure,
    handle_pool_timeout,
)
from app.errors.response import error_response

# Standard HTTP errors raised by Flask itself (unknown URL, wrong method, ...)
# are returned in the same format, with these codes.
_HTTP_CODES = {
    400: "bad_request",
    404: "not_found",
    405: "method_not_allowed",
    413: "payload_too_large",
    415: "unsupported_media_type",
}


def _handle_api_error(error: ApiError):
    """Translate domain errors into the shared response format."""
    return error_response(
        error.status,
        error.code,
        error.message,
        error.details,
        error.retry_after,
    )


def _handle_http_exception(error: HTTPException):
    """Preserve HTTP metadata in the shared response format."""
    code = _HTTP_CODES.get(error.code, "http_error")
    response = error_response(
        error.code, code, error.description or error.name
    )
    # A 405 must tell the client which methods are allowed.
    for name, value in error.get_headers():
        if name.lower() == "allow":
            response.headers["Allow"] = value
    return response


def _handle_unexpected_error(error: Exception):
    """Log unexpected failures and return a generic response."""
    # The traceback goes to the log. The client never sees it.
    metrics.increment("errors.internal")
    current_app.logger.exception(
        "Unhandled error (request_id=%s)", g.get("request_id")
    )
    return error_response(
        500, "internal_error", "An unexpected error occurred."
    )


def register_error_handlers(app: Flask) -> None:
    """Register domain, HTTP, and database error responses."""
    handlers = (
        (IntegrityError, handle_database_conflict),
        (DBAPIError, handle_database_failure),
        (PoolTimeout, handle_pool_timeout),
        (ApiError, _handle_api_error),
        (HTTPException, _handle_http_exception),
        (Exception, _handle_unexpected_error),
    )
    for error_type, handler in handlers:
        app.register_error_handler(error_type, handler)
