"""The deadlines of app/config.py on a real PostgreSQL: a query past its
time is stopped, the request answers 503, and migrations lift the limit
only for themselves."""

import os
from pathlib import Path

import pytest
from flask_migrate import upgrade
from sqlalchemy import text

from app import create_app, metrics
from app.database import db


@pytest.fixture
def quick_app(database_app, monkeypatch):
    """The real engine options, with a deadline of 200 ms."""
    monkeypatch.setenv("DATABASE_STATEMENT_TIMEOUT_MS", "200")
    app = create_app(
        "testing",
        overrides={
            "SQLALCHEMY_DATABASE_URI": os.environ["TEST_DATABASE_URL"],
        },
    )

    @app.get("/slow")
    def slow():
        db.session.execute(text("SELECT pg_sleep(1)"))
        return "", 204

    yield app
    with app.app_context():
        db.session.remove()
        db.engine.dispose()


def test_a_query_past_its_deadline_is_stopped_and_answers_503(quick_app):
    answer = quick_app.test_client().get("/slow")

    assert answer.status_code == 503
    assert answer.get_json()["error"]["code"] == "database_unavailable"
    assert metrics.count("database.unavailable") == 1


def test_every_connection_starts_with_its_deadlines(quick_app):
    with quick_app.app_context():
        settings = {
            name: db.session.execute(text(f"SHOW {name}")).scalar()
            for name in (
                "statement_timeout",
                "lock_timeout",
                "idle_in_transaction_session_timeout",
            )
        }

    assert settings == {
        "statement_timeout": "200ms",
        "lock_timeout": "3s",
        "idle_in_transaction_session_timeout": "30s",
    }


def test_migrations_give_the_connection_back_with_its_deadline(quick_app):
    directory = Path(__file__).resolve().parents[1] / "migrations"
    with quick_app.app_context():
        upgrade(directory=str(directory))
        # The pool hands the same connection out again.
        value = db.session.execute(text("SHOW statement_timeout")).scalar()

    assert value == "200ms"
