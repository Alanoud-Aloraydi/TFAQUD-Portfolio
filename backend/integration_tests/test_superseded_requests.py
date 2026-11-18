"""A request the patient can no longer accept, on PostgreSQL through the
real endpoints: when the patient makes their own circle, or finishes
another request, the other requests sent to their number stay in
«السابقة» with the reason, and each sender is told once."""

import pytest

from app.database import db
from app.push import RecordingPushSender
from integration_tests.helpers import Api
from integration_tests.test_push_api import Phone

BASE = "/api/v1/circle-requests"
PREVIOUS = "/api/v1/notifications/previous"
SELF = {"name": "Mine", "birth_date": "1950-01-02", "city": "Riyadh"}


@pytest.fixture(autouse=True)
def close_app_session(database_app):
    """Release request transactions before the next test truncates tables."""
    yield
    db.session.remove()


@pytest.fixture
def pushes(database_app, monkeypatch):
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return sender


def ask(phone, patient, mode="simplified"):
    answer = phone.call(
        "post", BASE,
        {"patient_phone_number": patient.phone_number,
         "proposed_app_mode": mode},
    )
    assert answer.status_code == 201, answer.json
    return answer.json["request"]["id"]


def test_making_an_own_circle_closes_the_request_with_its_reason(
    database_app, account, pushes
):
    reem, sami = account(name="Reem"), account(name="Sami")
    reem_phone = Phone(database_app, reem)
    request_id = ask(reem_phone, sami)
    patient = Api(database_app, sami)

    made = patient.post("/api/v1/circles/self", SELF)

    assert made.status_code == 201, made.json
    # Not waiting any more on either side, but in «السابقة» with why.
    assert reem_phone.call("get", BASE).json["sent"] == []
    assert patient.get(BASE).json["received"] == []
    [sent] = reem_phone.call("get", PREVIOUS).json["previous"]
    assert (sent["id"], sent["kind"], sent["status"], sent["other_name"]) == (
        request_id, "request_sent", "superseded", "Sami",
    )
    [received] = patient.get(PREVIOUS).json["previous"]
    assert (received["kind"], received["status"], received["other_name"]) == (
        "request_received", "superseded", "Reem",
    )
    # And the sender is told, with nothing to answer.
    [message] = pushes.to(reem_phone.token)
    assert message.kind == "request_superseded"
    assert message.title == "طلبك ما يمكن قبوله"
    assert message.body == (
        "ما يمكن قبول طلبك لرعاية Sami، لأن هذا الرقم صار له دائرة رعاية "
        "في تفقّد."
    )
    assert dict(message.target) == {"request_id": request_id}


def test_finishing_one_request_closes_the_others_only(
    database_app, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    sami = account(name="Sami")
    reem_phone, khaled_phone = Phone(database_app, reem), Phone(
        database_app, khaled
    )
    chosen = ask(reem_phone, sami)
    other = ask(khaled_phone, sami)
    patient = Api(database_app, sami)
    patient.post(f"{BASE}/{chosen}/respond", {"accept": True})

    done = patient.post(
        f"{BASE}/{chosen}/complete",
        {"birth_date": "1950-01-02", "city": "Riyadh"},
    )

    assert done.status_code == 201, done.json
    [closed] = pushes.to(khaled_phone.token)
    assert closed.kind == "request_superseded"
    assert dict(closed.target) == {"request_id": other}
    # Reem hears it was accepted and is ready, never that it closed.
    assert [m.kind for m in pushes.to(reem_phone.token)] == [
        "request_answer", "circle_ready",
    ]
    statuses = {
        item["id"]: item["status"]
        for item in patient.get(PREVIOUS).json["previous"]
    }
    assert statuses == {chosen: "completed", other: "superseded"}
