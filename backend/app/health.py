"""Check process health and the configured database connection."""

from flask import Blueprint, current_app, jsonify
from sqlalchemy import text

from app.database import db

bp = Blueprint("health", __name__, url_prefix="/api/v1")


@bp.get("/health")
def health():
    """Check PostgreSQL when configured; fake-only tests remain offline."""
    if "sqlalchemy" in current_app.extensions:
        db.session.execute(text("SELECT 1"))
    return jsonify(status="ok")
