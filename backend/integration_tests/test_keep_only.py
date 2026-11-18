"""`flask keep-only` before testers come, on PostgreSQL: only the kept
accounts stay, with everything of theirs; every other account goes, with
every circle that has one of them in it, and what waits for their numbers.
"""

from datetime import date

import pytest
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.care import CareService
from app.database import db
from app.demo_data import DEMO_PHONES, INVITED_PHONE, REQUEST_PHONE
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleRequest,
    MedicationDoseRecord,
    OtpRequest,
)

OMAR = "+966511111111"
STRANGER = "+966522222222"
TEAM = "+966536000000"
# How the team types them in PowerShell: local numbers, commas or spaces.
KEEP = ["500000001,500000002", "0500000003", "500000004", f"+{TEAM[1:]}"]


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release the command's transaction before the next test truncates."""
    yield
    db.session.remove()


@pytest.fixture
def town(database_app, database):
    """The demo story, and Omar: his own circle, and a place in the
    circle of Lina's mother. A stranger asked for a sign-in code."""
    result = database_app.test_cli_runner().invoke(args=["demo-data"])
    assert result.exit_code == 0, result.output
    client = database_app.test_client()
    for phone in (STRANGER, DEMO_PHONES[0]):
        asked = client.post(
            "/api/v1/auth/request-code", json={"phone_number": phone}
        )
        assert asked.status_code in (200, 201), asked.get_json()
    with Session(database) as session, session.begin():
        omar = Account(
            phone_number=OMAR, first_name="عمر", last_name="الحربي",
            display_name="عمر", birth_date=date(1985, 4, 2), city="الرياض",
        )
        session.add(omar)
        session.flush()
        lina = session.scalar(
            select(Account).where(Account.phone_number == DEMO_PHONES[0])
        )
        mother = session.scalar(
            select(CareCircle).where(CareCircle.first_name == "نورة")
        )
        care = CareService(session, _now(session))
        care.create_self(omar.id, "دائرتي", None, None)
        invited = care.invite_manager(lina.id, mother.id, OMAR)
        care.respond_invitation(omar.id, invited.id, True)
    return database


def _now(session):
    return session.scalar(select(func.now()))


def _keep(app, *extra):
    return app.test_cli_runner().invoke(args=["keep-only", *KEEP, *extra])


def _count(engine, model, *where):
    with Session(engine) as session:
        return session.scalar(
            select(func.count()).select_from(model).where(*where)
        )


def test_without_yes_it_only_says_what_would_go(database_app, town):
    before = _count(town, CareCircle)

    result = _keep(database_app)

    assert result.exit_code == 0, result.output
    assert "Accounts to delete (1):" in result.output
    assert OMAR in result.output
    assert f"{TEAM}  (no account yet)" in result.output
    # Omar's own circle and Lina's mother's, where he helps.
    assert "Circles to delete, whole (2):" in result.output
    assert "Nothing was deleted." in result.output
    assert _count(town, Account) == 4
    assert _count(town, CareCircle) == before


def test_with_yes_only_the_kept_and_their_own_circles_stay(
    database_app, town
):
    before = _count(town, CareCircle)

    result = _keep(database_app, "--yes")

    assert result.exit_code == 0, result.output
    assert "Done: 1 accounts and 2 circles deleted." in result.output
    with Session(town) as session:
        phones = set(session.scalars(select(Account.phone_number)))
    assert phones == set(DEMO_PHONES)
    assert _count(town, CareCircle) == before - 2
    assert _count(town, CareCircle, CareCircle.first_name == "نورة") == 0
    # Khaled's circle, and its month of doses, are as they were.
    assert _count(town, MedicationDoseRecord) > 0
    # The invitation to a number not kept is gone; the request to a kept
    # one still waits.
    assert _count(
        town,
        CareCircleInvitation,
        CareCircleInvitation.invitee_phone_number == INVITED_PHONE,
    ) == 0
    assert _count(
        town,
        CareCircleRequest,
        CareCircleRequest.patient_phone_number == REQUEST_PHONE,
    ) == 1
    assert _count(town, OtpRequest, OtpRequest.phone_number == STRANGER) == 0
    assert _count(
        town, OtpRequest, OtpRequest.phone_number == DEMO_PHONES[0]
    ) == 1


def test_a_wrong_number_stops_it_all(database_app, town):
    result = _keep(database_app, "12345", "--yes")

    assert result.exit_code != 0
    assert "is not a Saudi mobile number" in result.output
    assert _count(town, Account) == 4


def test_no_kept_account_here_deletes_nothing(database_app, town):
    result = database_app.test_cli_runner().invoke(
        args=["keep-only", "599999999", "--yes"]
    )

    assert result.exit_code != 0
    assert "nothing is deleted" in result.output
    assert _count(town, Account) == 4
