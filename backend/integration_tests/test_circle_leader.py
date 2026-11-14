"""«قائد الدائرة» against PostgreSQL: who leads, what each member may edit,
handing the circle over, and the bell's «السابقة»."""

from datetime import datetime, timedelta, timezone
from zoneinfo import ZoneInfo

import pytest
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.database import db
from app.models import CareCircle
from integration_tests.helpers import NOW, Api, add_manager, error_code
from integration_tests.helpers import offline_circle, run
from integration_tests.test_medications import plan_body

SELF = {"name": "My care", "birth_date": "1954-06-05", "city": "Riyadh"}


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


def url(circle_id, tail=""):
    return f"/api/v1/circles/{circle_id}{tail}"


def members(api, circle_id):
    """Each member's name: (is the leader, what they may edit)."""
    circle = api.get(url(circle_id)).json["circle"]
    return {
        m["display_name"]: (m["is_leader"], m["edit_access"])
        for m in circle["members"]
    }


def appointment_body():
    day = datetime.now(ZoneInfo("Asia/Riyadh")).date() + timedelta(days=3)
    return {
        "specialty": "eyes",
        "kind": "follow_up",
        "scheduled_on": day.isoformat(),
        "time_of_day": "10:00",
        "place": "Clinic",
    }


@pytest.fixture
def circle(database_app, database, account):
    """Reem made a circle for Nora (no account) and invited Khaled."""
    reem, khaled = account(name="Reem"), account(name="Khaled")
    made = offline_circle(database, reem)
    add_manager(database, reem, made, khaled)
    return (
        str(made.id),
        Api(database_app, reem),
        Api(database_app, khaled),
    )


def test_whoever_made_the_circle_leads_it(circle):
    circle_id, reem, khaled = circle

    assert members(khaled, circle_id) == {
        "Reem": (True, {"medications": True, "measurements": True,
                        "appointments": True}),
        "Khaled": (False, {"medications": True, "measurements": True,
                           "appointments": True}),
    }
    view = khaled.get(url(circle_id)).json["circle"]
    assert view["can_manage_members"] is False
    assert reem.get(url(circle_id)).json["circle"]["can_hand_over"] is True


def test_the_leader_lets_a_member_edit_one_area_and_not_another(circle):
    circle_id, reem, khaled = circle

    changed = reem.patch(
        url(circle_id, f"/members/{khaled.account.id}"),
        {"edit_access": {"medications": False}},
    )

    assert changed.status_code == 200, changed.json
    assert members(reem, circle_id)["Khaled"][1] == {
        "medications": False, "measurements": True, "appointments": True,
    }
    day = datetime.now(timezone.utc)
    # No new medicine; an appointment still.
    assert error_code(
        khaled.post(url(circle_id, "/medication-plans"), plan_body(day)), 403
    ) == "forbidden"
    made = khaled.post(url(circle_id, "/appointments"), appointment_body())
    assert made.status_code == 201, made.json
    home = khaled.get("/api/v1/home").json["care_circles"][0]
    assert (
        home["can_manage_medications"],
        home["can_manage_measurements"],
        home["can_manage_appointments"],
    ) == (False, True, True)


def test_a_member_allowed_nothing_only_reads(circle):
    circle_id, reem, khaled = circle

    # The app before the areas pauses all three at once.
    reem.patch(
        url(circle_id, f"/members/{khaled.account.id}"), {"can_edit": False}
    )

    view = khaled.get(url(circle_id))
    assert view.status_code == 200
    assert view.json["circle"]["your_edit_access"] == {
        "medications": False, "measurements": False, "appointments": False,
    }
    assert error_code(
        khaled.post(url(circle_id, "/appointments"), appointment_body()), 403
    ) == "forbidden"


def test_only_the_leader_manages_members(circle):
    circle_id, reem, khaled = circle

    answer = khaled.patch(
        url(circle_id, f"/members/{reem.account.id}"),
        {"edit_access": {"appointments": False}},
    )

    assert error_code(answer, 403) == "forbidden"
    assert error_code(
        khaled.delete(url(circle_id, f"/members/{reem.account.id}")), 403
    ) == "forbidden"


def test_the_leader_hands_the_circle_over_and_keeps_one_leader(circle):
    circle_id, reem, khaled = circle

    handed = reem.put(
        url(circle_id, "/leader"), {"account_id": str(khaled.account.id)}
    )

    assert handed.status_code == 200, handed.json
    assert {name: lead for name, (lead, _) in members(reem, circle_id)
            .items()} == {"Reem": False, "Khaled": True}
    # Reem leads no more.
    assert error_code(
        reem.patch(
            url(circle_id, f"/members/{khaled.account.id}"),
            {"can_edit": False},
        ),
        403,
    ) == "forbidden"
    # The new leader may now set what Reem edits.
    assert khaled.patch(
        url(circle_id, f"/members/{reem.account.id}"),
        {"edit_access": {"measurements": False}},
    ).status_code == 200


def test_when_the_leader_leaves_the_first_member_leads(circle):
    circle_id, reem, khaled = circle
    reem.put(url(circle_id, "/leader"), {"account_id": str(khaled.account.id)})

    assert khaled.post(url(circle_id, "/leave")).status_code == 204

    assert members(reem, circle_id)["Reem"][0] is True


def test_a_detailed_patient_always_leads_their_circle(
    database_app, database, account
):
    nora, khaled = account(name="Nora"), account(name="Khaled")
    nora_api = Api(database_app, nora)
    circle_id = nora_api.post("/api/v1/circles/self", SELF).json["circle"][
        "id"
    ]
    with Session(database) as session:
        made = session.get(CareCircle, circle_id)
    add_manager(database, nora, made, khaled)

    answer = nora_api.put(
        url(circle_id, "/leader"), {"account_id": str(khaled.id)}
    )

    assert error_code(answer, 409) == "patient_leads"
    view = nora_api.get(url(circle_id)).json["circle"]
    assert view["leader_account_id"] == str(nora.id)
    assert view["can_hand_over"] is False


def test_the_bell_lists_what_was_answered_for_30_days(
    database_app, database, account, monkeypatch
):
    # A day after the answers (`run` answers at the helpers' NOW).
    clock = ManualClock(NOW + timedelta(days=1))
    monkeypatch.setitem(database_app.extensions, "clock", clock)
    reem, khaled, sara = (
        account(name="Reem"), account(name="Khaled"), account(name="Sara"),
    )
    made = offline_circle(database, reem)
    add_manager(database, reem, made, khaled)
    declined = run(
        database, "invite_manager", reem.id, made.id, sara.phone_number
    )
    run(database, "respond_invitation", sara.id, declined.id, False)

    sent = Api(database_app, reem).get("/api/v1/notifications/previous")

    assert sent.status_code == 200, sent.json
    assert sorted(
        (item["kind"], item["status"], item["other_name"])
        for item in sent.json["previous"]
    ) == [
        ("invitation_sent", "accepted", "Khaled"),
        ("invitation_sent", "declined", "Sara"),
    ]
    [received] = Api(database_app, sara).get(
        "/api/v1/notifications/previous"
    ).json["previous"]
    assert (received["kind"], received["status"], received["other_name"]) == (
        "invitation_received", "declined", "Reem",
    )
    assert received["circle_name"] == "دائرة Nora"

    # 31 days later they are gone.
    clock.advance(days=31)
    assert Api(database_app, sara).get(
        "/api/v1/notifications/previous"
    ).json["previous"] == []
