"""Exercise the six-entity schema, workflows, and concurrent transactions."""

from concurrent.futures import ThreadPoolExecutor
from threading import Barrier

import pytest
from sqlalchemy import delete, inspect, select, text, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.database import db
from app.authz.postgres import PostgresCircleAccess
from app.authz.roles import CircleRole
from app.errors import Forbidden, ValidationFailed
from app.models import Account, CareCircle, CareCircleCreationRequest
from app.models import CareCircleManager, CareCircleManagerInvitation, Patient
from app.users.postgres import PostgresUserStore
from integration_tests.helpers import BIRTH, NOW, add_manager, count
from integration_tests.helpers import offline_circle, run


def test_circle_access_joins_an_existing_transaction(database, account):
    """Authorization composes with caller-owned transactions."""
    owner = account()
    circle = offline_circle(database, owner)
    with db.session.begin():
        assert (
            PostgresCircleAccess().role_in(owner.id.hex, circle.id.hex)
            == CircleRole.MANAGER
        )


def test_migrations_create_care_and_authentication_tables(database):
    """Authentication tables are separate from the six core care entities."""
    assert set(inspect(database).get_table_names()) == {
        "account",
        "care_circle",
        "patient",
        "care_circle_manager",
        "care_circle_creation_request",
        "care_circle_manager_invitation",
        "alembic_version",
        "account_session",
        "otp_challenge",
        "otp_send_attempt",
        "medication_plan",
        "medication_plan_version",
        "medication_schedule",
        "medication_schedule_day",
        "medication_dose_record",
    }


def test_incomplete_accounts_cannot_start_care(database, account):
    """Phone verification alone does not satisfy profile requirements."""
    owner = account(complete=False)
    with pytest.raises(ValidationFailed, match="profile"):
        offline_circle(database, owner)
    assert count(database, CareCircle) == 0


def test_self_care_has_patient_and_manager(database, account):
    """A detailed patient holds an actual manager membership."""
    owner = account()
    circle = run(database, "create_self", owner.id, "My care", BIRTH, "Riyadh")
    with Session(database) as session:
        patient = session.scalar(select(Patient))
        assert patient.account_id == owner.id
        assert patient.first_name is None
        assert patient.care_circle_id == circle.id
        assert session.get(Account, owner.id).app_mode == "detailed"
    assert count(database, CareCircleManager) == 1


def test_no_account_patient_does_not_create_an_account(database, account):
    """One caregiver account is enough for offline care."""
    offline_circle(database, account())
    assert count(database, Account) == 1
    with Session(database) as session:
        patient = session.scalar(select(Patient))
        assert patient.account_id is None
        assert (patient.first_name, patient.last_name) == ("Nora", "Family")


@pytest.mark.parametrize("missing", ["patient", "manager"])
def test_deferred_checks_reject_incomplete_circles(database, account, missing):
    """Existence checks execute at commit, after all inserts could finish."""
    owner = account("detailed")
    with pytest.raises(IntegrityError):
        with Session(database) as session, session.begin():
            circle = CareCircle(name="Incomplete")
            session.add(circle)
            session.flush()
            if missing == "patient":
                session.add(
                    CareCircleManager(
                        account_id=owner.id, care_circle_id=circle.id
                    )
                )
            else:
                session.add(
                    Patient(
                        care_circle_id=circle.id,
                        first_name="Nora",
                        last_name="Family",
                        birth_date=BIRTH,
                        city="Riyadh",
                    )
                )
    assert count(database, CareCircle) == 0


@pytest.mark.parametrize("mode", [None, "simplified"])
def test_database_rejects_non_detailed_managers(database, account, mode):
    """Direct SQL cannot bypass the manager mode restriction."""
    owner = account(mode)
    with pytest.raises(IntegrityError):
        with Session(database) as session, session.begin():
            circle = CareCircle(name="Invalid")
            session.add(circle)
            session.flush()
            session.add(
                CareCircleManager(
                    care_circle_id=circle.id, account_id=owner.id
                )
            )


def test_account_mode_is_immutable(database, account):
    """Changing an assigned mode fails even outside service code."""
    owner = account("detailed")
    with pytest.raises(IntegrityError):
        with database.begin() as connection:
            connection.execute(
                update(Account)
                .where(Account.id == owner.id)
                .values(app_mode="simplified")
            )


def test_names_have_one_source(database, account):
    """Linked patients cannot store a second conflicting name."""
    owner = account()
    run(database, "create_self", owner.id, "My care", BIRTH, "Riyadh")
    with pytest.raises(IntegrityError):
        with database.begin() as connection:
            connection.execute(update(Patient).values(first_name="Different"))


def test_detailed_patient_must_remain_a_manager(database, account):
    """Other managers do not replace the patient's required membership."""
    owner, other = account(), account()
    circle = run(database, "create_self", owner.id, "My care", BIRTH, "Riyadh")
    add_manager(database, owner, circle, other)
    with pytest.raises(IntegrityError):
        with database.begin() as connection:
            connection.execute(
                delete(CareCircleManager).where(
                    CareCircleManager.account_id == owner.id
                )
            )


def test_creation_requires_consent_and_completion(database, account):
    """Consent alone allocates neither a circle nor patient access."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "simplified",
    )
    assert count(database, CareCircle) == 0
    with pytest.raises(ValidationFailed, match="consent"):
        run(
            database,
            "complete_creation",
            patient.id,
            request.id,
            BIRTH,
            "Buraidah",
        )
    run(database, "respond_creation", patient.id, request.id, True)
    assert count(database, CareCircle) == 0
    circle = run(
        database,
        "complete_creation",
        patient.id,
        request.id,
        BIRTH,
        "Buraidah",
    )
    again = run(
        database,
        "complete_creation",
        patient.id,
        request.id,
        BIRTH,
        "Buraidah",
    )
    assert again.id == circle.id
    assert count(database, CareCircleManager) == 1
    with Session(database) as session:
        assert session.get(Account, patient.id).app_mode == "simplified"
        saved = session.get(CareCircleCreationRequest, request.id)
        assert saved.status == "completed"
        assert saved.completed_at == NOW


def test_completion_supersedes_competing_requests(database, account):
    """The losing request is superseded rather than declined."""
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
    run(
        database,
        "complete_creation",
        patient.id,
        requests[0].id,
        BIRTH,
        "Riyadh",
    )
    with Session(database) as session:
        assert (
            session.get(CareCircleCreationRequest, requests[1].id).status
            == "superseded"
        )
    assert count(database, CareCircleManager) == 2


def test_self_creation_supersedes_pending_request(database, account):
    """Receiving a request never prevents voluntary self-care."""
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Mother",
        "detailed",
    )
    run(database, "create_self", patient.id, "My care", BIRTH, "Riyadh")
    with Session(database) as session:
        assert (
            session.get(CareCircleCreationRequest, request.id).status
            == "superseded"
        )


def test_invitation_resend_and_acceptance_are_idempotent(database, account):
    """One pending invitation produces at most one membership."""
    owner, target = account(), account()
    circle = offline_circle(database, owner)
    first = run(
        database, "invite_manager", owner.id, circle.id, target.phone_number
    )
    resent = run(
        database, "invite_manager", owner.id, circle.id, target.phone_number
    )
    assert first.id == resent.id
    for _ in range(2):
        run(database, "respond_invitation", target.id, first.id, True)
    assert count(database, CareCircleManager) == 2
    run(database, "leave_circle", target.id, circle.id)
    with Session(database) as session:
        assert (
            session.get(CareCircleManagerInvitation, first.id).status
            == "accepted"
        )


def test_simplified_account_cannot_accept_management(database, account):
    """Existing simplified mode is not overwritten by an invitation."""
    owner, target = account(), account("simplified")
    circle = offline_circle(database, owner)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, target.phone_number
    )
    with pytest.raises(ValidationFailed, match="cannot change"):
        run(database, "respond_invitation", target.id, invitation.id, True)
    assert count(database, CareCircleManager) == 1


def test_wrong_account_cannot_respond(database, account):
    """Caller identity is matched against the verified target phone."""
    owner, target, stranger = account(), account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        target.phone_number,
        "Mother",
        "detailed",
    )
    with pytest.raises(Forbidden):
        run(database, "respond_creation", stranger.id, request.id, True)
    circle = offline_circle(database, owner)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, target.phone_number
    )
    with pytest.raises(Forbidden):
        run(database, "respond_invitation", stranger.id, invitation.id, True)


def test_last_manager_requires_explicit_deletion(database, account):
    """Canceling departure preserves care; confirmation keeps accounts."""
    owner = account()
    circle = offline_circle(database, owner)
    with pytest.raises(ValidationFailed, match="Explicit"):
        run(database, "leave_circle", owner.id, circle.id)
    assert count(database, CareCircle) == 1
    run(database, "leave_circle", owner.id, circle.id, confirm_delete=True)
    assert count(database, CareCircle) == 0
    assert count(database, Patient) == 0
    assert count(database, Account) == 1


def test_patient_controls_circle_deletion(database, account):
    """Another manager cannot veto deletion of the patient's own circle."""
    patient, other = account(), account()
    circle = run(
        database, "create_self", patient.id, "My care", BIRTH, "Riyadh"
    )
    add_manager(database, patient, circle, other)
    run(database, "delete_account", patient.id, patient_choice="delete")
    assert count(database, CareCircle) == 0
    assert count(database, Account) == 1


def test_continued_care_detaches_names_atomically(database, account):
    """The remaining manager keeps a named patient without an account."""
    patient, other = account(), account()
    circle = run(
        database, "create_self", patient.id, "My care", BIRTH, "Riyadh"
    )
    add_manager(database, patient, circle, other)
    run(database, "delete_account", patient.id, patient_choice="continue")
    with Session(database) as session:
        saved = session.scalar(select(Patient))
        assert saved.account_id is None
        assert (saved.first_name, saved.last_name) == ("Nora", "Family")
    assert count(database, CareCircleManager) == 1


def test_invitation_survives_sender_account_deletion(database, account):
    """Other managers may keep a pending invitation after its sender leaves."""
    owner, other, target = account(), account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, other)
    invitation = run(
        database, "invite_manager", owner.id, circle.id, target.phone_number
    )
    run(database, "delete_account", owner.id)
    with Session(database) as session:
        saved = session.get(CareCircleManagerInvitation, invitation.id)
        assert saved.status == "pending"
        assert saved.invited_by_account_id is None
    run(database, "respond_invitation", target.id, invitation.id, True)


def test_parallel_departures_cannot_remove_both_managers(database, account):
    """Independent connections serialize checks against the same circle."""
    first, second = account(), account()
    circle = offline_circle(database, first)
    add_manager(database, first, circle, second)
    barrier = Barrier(2)

    def leave(actor):
        barrier.wait(timeout=10)
        try:
            run(database, "leave_circle", actor.id, circle.id)
            return "left"
        except ValidationFailed:
            return "retained"

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(leave, (first, second)))
    assert sorted(results) == ["left", "retained"]
    assert count(database, CareCircleManager) == 1


def test_parallel_self_and_request_creation_make_one_circle(database, account):
    """The patient account lock covers creation before any circle exists."""
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
    barrier = Barrier(2)

    def create(method):
        barrier.wait(timeout=10)
        try:
            if method == "self":
                run(
                    database,
                    "create_self",
                    patient.id,
                    "My care",
                    BIRTH,
                    "Riyadh",
                )
            else:
                run(
                    database,
                    "complete_creation",
                    patient.id,
                    request.id,
                    BIRTH,
                    "Riyadh",
                )
            return "created"
        except ValidationFailed:
            return "rejected"

    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(create, ("self", "request")))
    assert sorted(results) == ["created", "rejected"]
    assert count(database, Patient) == 1


def test_postgres_adapter_preserves_user_contract(database, database_app):
    """The account survives a fresh app context and keeps API fields."""
    store = PostgresUserStore()
    first, created = store.get_or_create_by_phone("+966501234567", NOW)
    assert created and not first.profile_complete
    saved = store.update_profile(first.id, "Nora", "Family", "Nora")
    with database_app.app_context():
        second, created = PostgresUserStore().get_or_create_by_phone(
            first.phone, NOW
        )
        assert not created
        assert second.id == first.id
        assert second.to_dict() == saved.to_dict()
        db.session.remove()


def test_schema_rejects_completed_request_without_circle(database, account):
    """Completion status cannot exist independently of activation fields."""
    owner = account()
    with pytest.raises(IntegrityError):
        with database.begin() as connection:
            connection.execute(
                text(
                    "INSERT INTO care_circle_creation_request "
                    "(requested_by_account_id, patient_phone_number, "
                    "proposed_circle_label, proposed_app_mode, status) "
                    "VALUES (:owner, '+966501234568', 'Mother', "
                    "'detailed', 'completed')"
                ),
                {"owner": owner.id},
            )
