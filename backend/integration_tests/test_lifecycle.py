"""Integration coverage for lifecycle boundaries and persistence adapters."""

from concurrent.futures import ThreadPoolExecutor
from datetime import timedelta
from pathlib import Path
from threading import Barrier

import pytest
from flask_migrate import downgrade, upgrade
from sqlalchemy import delete, event, inspect, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import db
from app.errors import Forbidden, NotFound, ValidationFailed
from app.models import Account, CareCircle, CareCircleCreationRequest
from app.models import CareCircleManager, CareCircleManagerInvitation, Patient
from app.users.postgres import PostgresUserStore
from integration_tests.helpers import BIRTH, NOW, add_manager, count
from integration_tests.helpers import offline_circle, run


def test_simplified_patient_can_edit_own_profile(database, account):
    """Profile editing is permitted independently of management rights."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "simplified",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    circle = run(
        database, "complete_creation", patient.id, request.id, BIRTH, "Riyadh"
    )
    saved = run(
        database,
        "update_patient_profile",
        patient.id,
        circle.id,
        BIRTH,
        "Buraidah",
        latitude=26.35,
        longitude=43.97,
    )
    assert saved.city == "Buraidah"
    assert count(database, CareCircleManager) == 1
    with pytest.raises(Forbidden):
        run(database, "rename_circle", patient.id, circle.id, "New name")
    with pytest.raises(Forbidden):
        run(
            database,
            "update_patient_profile",
            account().id,
            circle.id,
            BIRTH,
            "Elsewhere",
        )


def test_patient_can_delete_circle_without_deleting_account(database, account):
    """Patient control is not contingent on the other manager's approval."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "simplified",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    circle = run(
        database, "complete_creation", patient.id, request.id, BIRTH, "Riyadh"
    )
    run(database, "delete_circle", patient.id, circle.id, confirm=True)
    assert count(database, Account) == 2
    assert count(database, CareCircle) == 0


def test_manager_cannot_delete_another_patients_circle(database, account):
    """A manager cannot use circle deletion to override the linked patient."""
    patient, other = account(), account()
    circle = run(
        database, "create_self", patient.id, "My care", BIRTH, "Riyadh"
    )
    add_manager(database, patient, circle, other)
    with pytest.raises(Forbidden):
        run(database, "delete_circle", other.id, circle.id, confirm=True)
    assert count(database, CareCircle) == 1


def test_failed_creation_rolls_back_mode_assignment(database, account):
    """A failed multi-step operation must not leave partial writes behind."""
    owner = account()
    with pytest.raises(ValidationFailed):
        run(
            database,
            "create_self",
            owner.id,
            "My care",
            NOW.date() + timedelta(days=1),
            "Riyadh",
        )
    with Session(database) as session:
        assert session.get(Account, owner.id).app_mode is None
    assert count(database, CareCircle) == 0


def test_canceling_consent_does_not_change_assigned_mode(database, account):
    """Canceling a request does not undo the patient's immutable mode."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "simplified",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    run(database, "cancel_creation", patient.id, request.id)
    with Session(database) as session:
        assert session.get(Account, patient.id).app_mode == "simplified"
        assert (
            session.get(CareCircleCreationRequest, request.id).status
            == "canceled"
        )


def test_deleting_patient_account_cancels_accepted_request(database, account):
    """SET NULL cannot leave accepted consent without its patient account."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "simplified",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    run(database, "delete_account", patient.id)
    with Session(database) as session:
        saved = session.get(CareCircleCreationRequest, request.id)
        assert saved.status == "canceled"
        assert saved.responded_by_account_id is None


def test_only_one_accepted_incomplete_request(database, account):
    """A second consent does not replace the first accepted care path."""
    first, second, patient = account(), account(), account()
    requests = [
        run(
            database,
            "request_creation",
            owner.id,
            patient.phone_number,
            "Mother",
            "detailed",
        )
        for owner in (first, second)
    ]
    run(database, "respond_creation", patient.id, requests[0].id, True)
    with pytest.raises(ValidationFailed, match="accepted care"):
        run(database, "respond_creation", patient.id, requests[1].id, True)


def test_other_manager_can_cancel_pending_invitation(database, account):
    """Invitation management is not restricted to the original sender."""
    owner, other, target = account(), account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, other)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, target.phone_number
    )
    run(database, "cancel_invitation", other.id, invitation.id)
    with Session(database) as session:
        assert (
            session.get(CareCircleManagerInvitation, invitation.id).status
            == "canceled"
        )


def test_direct_parallel_deletes_cannot_bypass_integrity(database, account):
    """Database locking also protects writes made outside CareService."""
    first, second = account(), account()
    circle = offline_circle(database, first)
    add_manager(database, first, circle, second)
    barrier = Barrier(2)

    def remove(actor):
        barrier.wait(timeout=10)
        try:
            with database.begin() as connection:
                connection.execute(
                    delete(CareCircleManager).where(
                        CareCircleManager.account_id == actor.id
                    )
                )
            return "deleted"
        except IntegrityError:
            return "rejected"

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(remove, (first, second)))
    assert sorted(results) == ["deleted", "rejected"]
    assert count(database, CareCircleManager) == 1


def test_concurrent_first_sign_ins_create_one_account(database, database_app):
    """The PostgreSQL adapter preserves get-or-create under contention."""
    barrier = Barrier(8)

    def sign_in(_):
        with database_app.app_context():
            barrier.wait(timeout=10)
            result = PostgresUserStore().get_or_create_by_phone(
                "+966501234567", NOW
            )
            db.session.remove()
            return result

    with ThreadPoolExecutor(max_workers=8) as pool:
        results = list(pool.map(sign_in, range(8)))
    assert len({user.id for user, _ in results}) == 1
    assert sum(created for _, created in results) == 1


def test_api_registration_and_profile_use_postgres(database, database_app):
    """The existing Flutter endpoints persist an account and its names."""
    client = database_app.test_client()
    phone = "+966501234567"
    response = client.post(
        "/api/v1/auth/request-code", json={"phone_number": phone}
    )
    verification = response.get_json()["verification_id"]
    sms = database_app.extensions["sms_sender"]
    result = client.post(
        "/api/v1/auth/verify-code",
        json={
            "verification_id": verification,
            "code": sms.last_message_to(phone).code,
        },
    ).get_json()
    assert result["account"]["profile_complete"] is False
    saved = client.put(
        "/api/v1/accounts/me/profile",
        json={
            "first_name": "Nora",
            "last_name": "Family",
            "display_name": "Nora",
        },
        headers={"Authorization": f"Bearer {result['access_token']}"},
    )
    assert saved.status_code == 200
    with Session(database) as session:
        assert session.scalar(select(Account)).first_name == "Nora"


def test_migrations_round_trip(database, database_app):
    """Downgrade and upgrade work on the empty isolated test database."""
    directory = str(Path(__file__).resolve().parents[1] / "migrations")
    downgrade(directory=directory, revision="base")
    assert set(inspect(database).get_table_names()) == {"alembic_version"}
    upgrade(directory=directory)
    assert "patient" in inspect(database).get_table_names()


def test_sign_in_survives_deletion_before_account_read(database):
    """A conflicting account may disappear before the following SELECT."""
    store = PostgresUserStore()
    original, _ = store.get_or_create_by_phone("+966501234567", NOW)
    deleted = False

    def delete_account(connection, cursor, statement, *args):
        nonlocal deleted
        if deleted or "ON CONFLICT" not in statement:
            return
        deleted = True
        with database.begin() as writer:
            writer.execute(delete(Account).where(Account.id == original.id))

    event.listen(database, "after_cursor_execute", delete_account)
    try:
        result, created = store.get_or_create_by_phone(original.phone, NOW)
    finally:
        event.remove(database, "after_cursor_execute", delete_account)
    assert deleted and created
    assert result.id != original.id
    assert count(database, Account) == 1


def test_completion_handles_deletion_before_request_lock(database, account):
    """Circle deletion can remove a request between its two reads."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "detailed",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    circle = run(
        database, "complete_creation", patient.id, request.id, BIRTH, "Riyadh"
    )
    deleted = False

    def delete_circle(connection, cursor, statement, *args):
        nonlocal deleted
        if deleted or "FROM care_circle_creation_request" not in statement:
            return
        deleted = True
        with database.begin() as writer:
            writer.execute(
                delete(CareCircle).where(CareCircle.id == circle.id)
            )

    event.listen(database, "after_cursor_execute", delete_circle)
    try:
        with pytest.raises(NotFound):
            run(
                database,
                "complete_creation",
                patient.id,
                request.id,
                BIRTH,
                "Riyadh",
            )
    finally:
        event.remove(database, "after_cursor_execute", delete_circle)
    assert deleted
