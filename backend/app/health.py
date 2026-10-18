from flask import Blueprint, jsonify

bp = Blueprint("health", __name__, url_prefix="/api/v1")


@bp.get("/health")
def health():
    """Answers 200 while the server process is running.

    It does not check the database yet. The database check is added with the
    PostgreSQL work (TFQD-7); the hosting health check (TFQD-10) uses this URL.
    """
    return jsonify(status="ok")
