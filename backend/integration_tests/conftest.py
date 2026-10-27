"""Opt-in integration tests against an isolated PostgreSQL test database."""

import os
from pathlib import Path

import pytest
from flask_migrate import upgrade
from sqlalchemy import text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from app import create_app
from app.database import db


@pytest.fixture(scope="session")
def database_app():
    """Apply real migrations only to an explicitly selected test database."""
    url = os.environ.get("TEST_DATABASE_URL")
    if not url:
        pytest.skip(
            "Set TEST_DATABASE_URL to run PostgreSQL integration tests"
        )
    parsed = make_url(url)
    if parsed.get_backend_name() != "postgresql" or not (
        parsed.database or ""
    ).endswith("_test"):
        raise pytest.UsageError("Database name must end in _test")
    app = create_app(
        "testing",
        overrides={
            "SQLALCHEMY_DATABASE_URI": url,
            "SQLALCHEMY_ENGINE_OPTIONS": {
                "pool_pre_ping": True,
                "connect_args": {
                    "options": (
                        "-c lock_timeout=5000 -c statement_timeout=15000"
                    ),
                },
            },
        },
    )
    with app.app_context():
        directory = Path(__file__).resolve().parents[1] / "migrations"
        upgrade(directory=str(directory))
        yield app
        db.session.remove()
        db.engine.dispose()


@pytest.fixture
def database(database_app):
    """Clear application tables only in the dedicated test database."""
    with db.engine.begin() as connection:
        connection.execute(
            text(
                "TRUNCATE otp_challenge, account, care_circle, patient, care_circle_manager, "
                "care_circle_creation_request, care_circle_manager_invitation "
                "CASCADE"
            )
        )
    return db.engine


@pytest.fixture
def account(database):
    """Create complete accounts with distinct phones unless overridden."""
    from app.models import Account

    counter = 0

    def create(mode=None, complete=True, name="Nora"):
        nonlocal counter
        counter += 1
        with Session(database, expire_on_commit=False) as session:
            with session.begin():
                row = Account(
                    phone_number=f"+966500{counter:06d}",
                    app_mode=mode,
                    first_name=name if complete else None,
                    last_name="Family" if complete else None,
                    display_name=name if complete else None,
                )
                session.add(row)
                session.flush()
            return row

    return create
