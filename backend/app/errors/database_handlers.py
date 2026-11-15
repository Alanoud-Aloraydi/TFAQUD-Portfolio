"""The answers to database failures: a rejected write, an outage, a
busy pool."""

from flask import current_app
from sqlalchemy.exc import DBAPIError, IntegrityError, OperationalError
from sqlalchemy.exc import TimeoutError as PoolTimeout

from app import metrics
from app.errors.response import error_response


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
