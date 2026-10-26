"""Home authorization through Flask against real PostgreSQL."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import CareCircleManager
from integration_tests.helpers import BIRTH, add_manager, offline_circle, run

PATH = "/api/v1/home"


def signed_in(app, account):
    """Issue a real persisted session without sending an SMS."""
    issued = app.extensions["session_service"].create_session(account.id.hex)
    return {"Authorization": "Bearer " + issued.access_token}


def test_home_requires_authentication(database_app, database):
    response = database_app.test_client().get(PATH)
    assert response.status_code == 401


def test_home_returns_empty_circles_and_own_identity(database_app, account):
    owner = account()
    response = database_app.test_client().get(
        PATH, headers=signed_in(database_app, owner)
    )
    assert response.status_code == 200
    assert response.json == {
        "account": {
            "id": owner.id.hex,
            "display_name": "Nora",
            "profile_complete": True,
        },
        "care_circles": [],
    }
    assert response.headers["Cache-Control"] == "no-store"


def test_home_excludes_other_circles_and_pending_invitations(
    database_app, database, account
):
    owner, other = account(), account()
    visible = offline_circle(database, owner)
    hidden = offline_circle(database, other)
    run(database, "invite_manager", other.id, hidden.id, owner.phone_number)
    response = database_app.test_client().get(
        PATH + "?account_id=" + other.id.hex,
        headers=signed_in(database_app, owner),
    )
    assert response.status_code == 200
    assert response.json["account"]["id"] == owner.id.hex
    assert response.json["care_circles"] == [
        {"id": str(visible.id), "name": visible.name}
    ]


def test_home_lists_patient_manager_circle_once(
    database_app, database, account
):
    owner = account()
    circle = run(database, "create_self", owner.id, "My care", BIRTH, "Riyadh")
    response = database_app.test_client().get(
        PATH, headers=signed_in(database_app, owner)
    )
    assert response.json["care_circles"] == [
        {"id": str(circle.id), "name": circle.name}
    ]


def test_home_includes_patient_without_management(
    database_app, database, account
):
    owner, patient = account(), account()
    request = run(
        database,
        "request_creation",
        owner.id,
        patient.phone_number,
        "Care for",
        "simplified",
    )
    run(database, "respond_creation", patient.id, request.id, True)
    circle = run(
        database, "complete_creation", patient.id, request.id, BIRTH, "Riyadh"
    )
    response = database_app.test_client().get(
        PATH, headers=signed_in(database_app, patient)
    )
    assert response.json["care_circles"][0]["id"] == str(circle.id)


def test_home_rechecks_membership_on_each_request(
    database_app, database, account
):
    owner, member = account(), account()
    circle = offline_circle(database, owner)
    add_manager(database, owner, circle, member)
    headers = signed_in(database_app, member)
    client = database_app.test_client()
    assert len(client.get(PATH, headers=headers).json["care_circles"]) == 1
    with Session(database) as session, session.begin():
        membership = session.scalar(
            select(CareCircleManager).where(
                CareCircleManager.account_id == member.id,
                CareCircleManager.care_circle_id == circle.id,
            )
        )
        session.delete(membership)
    assert client.get(PATH, headers=headers).json["care_circles"] == []


def test_incomplete_profile_does_not_start_home(database_app, account):
    owner = account(complete=False)
    response = database_app.test_client().get(
        PATH, headers=signed_in(database_app, owner)
    )
    assert response.json["account"]["profile_complete"] is False
    assert response.json["care_circles"] == []


def test_signed_out_session_cannot_read_home(database_app, account):
    headers = signed_in(database_app, account())
    client = database_app.test_client()
    assert (
        client.post("/api/v1/auth/sign-out", headers=headers).status_code
        == 204
    )
    assert client.get(PATH, headers=headers).status_code == 401
