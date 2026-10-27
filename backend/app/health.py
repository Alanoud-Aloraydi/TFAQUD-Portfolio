"""Check process health, the database connection and the schema version."""

from functools import lru_cache
from pathlib import Path

from alembic.script import ScriptDirectory
from flask import Blueprint, current_app, jsonify
from sqlalchemy import inspect, text

from app.database import db
from app.errors import ServiceUnavailable

bp = Blueprint("health", __name__, url_prefix="/api/v1")

_MIGRATIONS = Path(__file__).resolve().parents[1] / "migrations"


@lru_cache(maxsize=1)
def expected_revision() -> str:
    """The newest migration in the code. It cannot change while running."""
    return ScriptDirectory(str(_MIGRATIONS)).get_current_head()


def _database_revision() -> str | None:
    """The migration the database is at, or None for an empty database."""
    connection = db.session.connection()
    if not inspect(connection).has_table("alembic_version"):
        return None
    return connection.execute(
        text("SELECT version_num FROM alembic_version")
    ).scalar()


@bp.get("/health")
def health():
    """Check PostgreSQL when configured; fake-only tests remain offline.

    A database that is reachable but not migrated to the newest version
    answers 503, so a new or old database is noticed here and not later as a
    confusing error on the first sign-in.
    """
    if "sqlalchemy" in current_app.extensions:
        db.session.execute(text("SELECT 1"))
        if _database_revision() != expected_revision():
            raise ServiceUnavailable(
                "The database tables are missing or out of date. "
                "Run: flask --app wsgi db upgrade",
                code="database_not_migrated",
            )
    return jsonify(status="ok")
