"""Database failures must roll back safely without leaking SQL values."""

from sqlalchemy.exc import OperationalError, ProgrammingError
from sqlalchemy import text, update
from sqlalchemy.orm import Session

import pytest

from app import create_app
from app.database import db
from app.models import Account
from app.models import CareCircle, CareCircleManager, Patient
from integration_tests.helpers import BIRTH


def test_conflict_is_safe_and_next_request_still_works(database):
    """Reject an invalid write with a stable response, then reuse the app."""
    app = create_app(
        "testing", overrides={"SQLALCHEMY_DATABASE_URI": database.url}
    )

    @app.get("/test/conflict")
    def conflict():
        db.session.add(Account(phone_number="private-invalid-value"))
        db.session.flush()
        return {}

    client = app.test_client()
    response = client.get("/test/conflict")
    assert response.status_code == 409
    assert response.get_json()["error"]["code"] == "data_conflict"
    assert "private-invalid-value" not in response.get_data(as_text=True)
    assert client.get("/api/v1/health").status_code == 200
    with app.app_context():
        db.engine.dispose()


def test_connection_failure_does_not_log_parameters(database, caplog):
    """Translate a driver failure without logging its SQL or parameters."""
    app = create_app(
        "testing", overrides={"SQLALCHEMY_DATABASE_URI": database.url}
    )

    @app.get("/test/unavailable")
    def unavailable():
        raise OperationalError(
            "private-sql", {"secret": "private-value"}, Exception("private")
        )

    response = app.test_client().get("/test/unavailable")
    assert response.status_code == 503
    assert response.get_json()["error"]["code"] == "database_unavailable"
    assert "private-value" not in caplog.text
    assert "private-sql" not in response.get_data(as_text=True)
    with app.app_context():
        db.engine.dispose()


def test_patient_activation_waits_for_account_profile_update(
    database, account
):
    """A simultaneous profile clear cannot race patient activation."""
    owner, patient = account("detailed"), account("simplified")
    with database.connect() as connection:
        transaction = connection.begin()
        connection.execute(
            update(Account)
            .where(Account.id == patient.id)
            .values(first_name=None, last_name=None, display_name=None)
        )
        try:
            with pytest.raises(OperationalError) as captured:
                with Session(database) as session, session.begin():
                    session.execute(text("SET LOCAL lock_timeout = '200ms'"))
                    circle = CareCircle(name="Concurrent care")
                    session.add(circle)
                    session.flush()
                    session.add(
                        CareCircleManager(
                            care_circle_id=circle.id, account_id=owner.id
                        )
                    )
                    session.add(
                        Patient(
                            care_circle_id=circle.id,
                            account_id=patient.id,
                            birth_date=BIRTH,
                            city="Riyadh",
                        )
                    )
                    session.flush()
            assert captured.value.orig.sqlstate == "55P03"
        finally:
            transaction.rollback()


def test_programming_error_is_not_database_unavailability(database, caplog):
    """SQL programming failures return 500 without exposing SQL values."""
    app = create_app(
        "testing", overrides={"SQLALCHEMY_DATABASE_URI": database.url}
    )

    @app.get("/test/programming-error")
    def programming_error():
        raise ProgrammingError(
            "private-sql", {"secret": "private-value"}, Exception("private")
        )

    response = app.test_client().get("/test/programming-error")
    assert response.status_code == 500
    assert response.get_json()["error"]["code"] == "internal_error"
    assert "private-value" not in caplog.text
    assert "private-sql" not in caplog.text
    assert "private" not in response.get_data(as_text=True)
    with app.app_context():
        db.engine.dispose()
