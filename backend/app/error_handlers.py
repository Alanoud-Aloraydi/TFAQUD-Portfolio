"""Every error handler of the app: API errors, HTTP errors, database
failures (a rejected write, an outage, a busy pool) and anything
unexpected, each answered in the one error format."""

from flask import Flask, current_app, g
from sqlalchemy.exc import (
    DBAPIError,
    IntegrityError,
    OperationalError,
    TimeoutError as PoolTimeout,
)
from werkzeug.exceptions import HTTPException

from app import metrics
from app.errors import ApiError, error_response


def handle_database_conflict(error: IntegrityError):
    """Roll back rejected writes without exposing SQL or patient values."""
    from app.database import db

    db.session.rollback()
    # The rule's name and our own fixed messages say which rule refused
    # the write; the failing row (the diagnostic's detail) is left out.
    diag = getattr(error.orig, "diag", None)
    metrics.increment("database.conflict")
    current_app.logger.warning(
        "Database refused a write: SQLSTATE=%s, rule=%s, %s",
        getattr(error.orig, "sqlstate", None),
        getattr(diag, "constraint_name", None),
        getattr(diag, "message_primary", None),
    )
    return error_response(
        409, "data_conflict", "The change conflicts with current data."
    )


def handle_database_failure(error: DBAPIError):
    """Distinguish operational failures from database programming errors."""
    from app.database import db

    db.session.rollback()
    # A query or a lock past its deadline (app/config/database.py) is one
    # of these.
    if isinstance(error, OperationalError) or error.connection_invalidated:
        metrics.increment("database.unavailable")
        current_app.logger.warning("Database unavailable; request rolled back")
        return error_response(
            503, "database_unavailable", "The database is unavailable."
        )
    metrics.increment("errors.internal")
    current_app.logger.error(
        "Database operation failed: %s, SQLSTATE=%s",
        type(error).__name__,
        getattr(error.orig, "sqlstate", None),
    )
    return error_response(
        500, "internal_error", "An unexpected error occurred."
    )


def handle_pool_timeout(error: PoolTimeout):
    """Every connection of the pool stayed busy past its deadline."""
    metrics.increment("database.unavailable")
    current_app.logger.warning("No free database connection in time")
    return error_response(
        503, "database_unavailable", "The database is unavailable."
    )


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
