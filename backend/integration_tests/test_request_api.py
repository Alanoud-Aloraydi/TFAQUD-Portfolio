"""Circle creation requests and consent through Flask on PostgreSQL."""

from datetime import timedelta
from uuid import UUID

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.clock import ManualClock
from app.models import Account, CareCircle, CareCircleCreationRequest
from app.models import CareCircleManager, Patient
from integration_tests.helpers import Api, count, error_code

BASE = "/api/v1/circle-requests"
REQUEST = {"circle_label": "Mother", "proposed_app_mode": "simplified"}
BASICS = {"birth_date": "1950-01-02", "city": "Buraydah"}


def send(api, patient, **change):
    body = {"patient_phone_number": patient.phone_number, **REQUEST, **change}
    return api.post(BASE, body)


def test_request_from_sending_to_the_new_circle(
    database_app, database, account
):
    requester = account(name="Reem")
    patient = account(name="Noura")
    sender, receiver = Api(database_app, requester), Api(database_app, patient)

    sent = send(sender, patient)
    assert sent.status_code == 201
    request_id = sent.json["request"]["id"]
    assert sent.json["request"]["status"] == "pending"
    assert sent.json["request"]["care_circle_id"] is None

    # The sender sees it as sent, the patient sees it as received.
    assert [r["id"] for r in sender.get(BASE).json["sent"]] == [request_id]
    assert sender.get(BASE).json["received"] == []
    received = receiver.get(BASE).json["received"]
    assert len(received) == 1
    assert received[0]["id"] == request_id
    assert received[0]["circle_name"] == "Mother Noura"
    assert received[0]["proposed_app_mode"] == "simplified"
    assert received[0]["requested_by"] == {
        "display_name": "Reem",
        "first_name": "Reem",
        "last_name": "Family",
    }
    assert count(database, CareCircle) == 0

    # Accepting is consent only: still no circle.
    accepted = receiver.post(f"{BASE}/{request_id}/respond", {"accept": True})
    assert accepted.json["request"]["status"] == "accepted"
    assert count(database, CareCircle) == 0
    assert sender.get(BASE).json["sent"][0]["status"] == "accepted"
    assert len(receiver.get(BASE).json["received"]) == 1

    # Completing the basic data creates the circle.
    done = receiver.post(f"{BASE}/{request_id}/complete", BASICS)
    assert done.status_code == 201
    circle = done.json["circle"]
    assert circle["name"] == "Mother Noura"
    assert circle["role"] == "simplified_patient"
    assert circle["patient"]["is_you"] is True
    assert circle["patient"]["app_mode"] == "simplified"
    assert [m["display_name"] for m in circle["members"]] == ["Reem"]
    assert sender.get(BASE).json["sent"] == []
    assert receiver.get(BASE).json["received"] == []
    for api, can_manage in ((sender, True), (receiver, False)):
        listed = api.get("/api/v1/home").json["care_circles"]
        assert listed == [
            {
                "id": circle["id"],
                "name": "Mother Noura",
                "can_manage_medications": can_manage,
            }
        ]
    with Session(database) as session:
        row = session.get(CareCircleCreationRequest, UUID(request_id))
        assert row.status == "completed"
        assert str(row.care_circle_id) == circle["id"]


def test_a_detailed_patient_also_manages_the_circle(
    database_app, database, account
):
    requester, patient = account(name="Reem"), account(name="Noura")
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient, proposed_app_mode="detailed").json[
        "request"
    ]["id"]
    receiver.post(f"{BASE}/{request_id}/respond", {"accept": True})

    done = receiver.post(f"{BASE}/{request_id}/complete", BASICS)

    circle = done.json["circle"]
    assert circle["role"] == "manager"
    assert sorted(m["display_name"] for m in circle["members"]) == [
        "Noura",
        "Reem",
    ]
    assert count(database, CareCircleManager) == 2


def test_the_basic_data_and_medical_profile_are_saved_together(
    database_app, database, account
):
    requester, patient = account(), account(name="Noura")
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient).json["request"]["id"]
    receiver.post(f"{BASE}/{request_id}/respond", {"accept": True})

    done = receiver.post(
        f"{BASE}/{request_id}/complete",
        {
            **BASICS,
            "latitude": 26.35,
            "longitude": 43.97,
            "medical_profile": {
                "blood_type": "A+",
                "allergies": {"status": "none"},
            },
        },
    )

    circle_id = done.json["circle"]["id"]
    assert done.json["circle"]["patient"]["latitude"] == 26.35
    profile = receiver.get(f"/api/v1/circles/{circle_id}/medical-profile")
    assert profile.json["medical_profile"]["blood_type"] == "A+"
    assert profile.json["medical_profile"]["allergies"]["status"] == "none"


def test_a_failed_completion_keeps_the_accepted_request(
    database_app, database, account
):
    """A mistake in the form creates nothing, and the patient can retry."""
    requester, patient = account(), account()
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient).json["request"]["id"]
    receiver.post(f"{BASE}/{request_id}/respond", {"accept": True})

    bad = receiver.post(
        f"{BASE}/{request_id}/complete",
        {
            **BASICS,
            "medical_profile": {
                "conditions": {"status": "listed", "codes": []}
            },
        },
    )

    assert error_code(bad, 422) == "empty_selection"
    assert count(database, CareCircle) == 0
    assert count(database, Patient) == 0
    assert receiver.get(BASE).json["received"][0]["status"] == "accepted"
    retry = receiver.post(f"{BASE}/{request_id}/complete", BASICS)
    assert retry.status_code == 201


def test_completing_twice_returns_the_same_circle(
    database_app, database, account
):
    requester, patient = account(), account()
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient).json["request"]["id"]
    receiver.post(f"{BASE}/{request_id}/respond", {"accept": True})

    first = receiver.post(f"{BASE}/{request_id}/complete", BASICS)
    second = receiver.post(f"{BASE}/{request_id}/complete", BASICS)

    assert second.json["circle"]["id"] == first.json["circle"]["id"]
    assert count(database, CareCircle) == 1


def test_a_circle_needs_the_consent_first(database_app, database, account):
    requester, patient = account(), account()
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient).json["request"]["id"]

    response = receiver.post(f"{BASE}/{request_id}/complete", BASICS)

    assert error_code(response, 422) == "consent_required"
    assert count(database, CareCircle) == 0


def test_the_sender_cannot_give_the_consent(database_app, database, account):
    requester, patient = account(), account()
    sender = Api(database_app, requester)
    request_id = send(sender, patient).json["request"]["id"]

    response = sender.post(f"{BASE}/{request_id}/respond", {"accept": True})

    assert error_code(response, 404) == "not_found"
    with Session(database) as session:
        row = session.scalar(select(CareCircleCreationRequest))
        assert row.status == "pending"


def test_a_request_is_hidden_from_strangers(database_app, database, account):
    requester, patient, stranger = account(), account(), account()
    request_id = send(Api(database_app, requester), patient).json["request"][
        "id"
    ]
    other = Api(database_app, stranger)

    for call in (
        other.post(f"{BASE}/{request_id}/respond", {"accept": True}),
        other.post(f"{BASE}/{request_id}/complete", BASICS),
        other.delete(f"{BASE}/{request_id}"),
        other.post(f"{BASE}/not-an-id/respond", {"accept": True}),
    ):
        assert error_code(call, 404) == "not_found"
    assert other.get(BASE).json == {"sent": [], "received": []}


def test_declining_is_shown_to_the_sender_for_a_week(
    database_app, database, account, monkeypatch
):
    requester, patient = account(), account()
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient).json["request"]["id"]

    declined = receiver.post(f"{BASE}/{request_id}/respond", {"accept": False})

    assert declined.json["request"]["status"] == "declined"
    assert receiver.get(BASE).json["received"] == []
    assert [r["status"] for r in sender.get(BASE).json["sent"]] == ["declined"]
    with Session(database) as session:
        responded = session.scalar(
            select(CareCircleCreationRequest.responded_at)
        )
    later = ManualClock(responded + timedelta(days=8))
    monkeypatch.setitem(database_app.extensions, "clock", later)
    assert sender.get(BASE).json["sent"] == []
    # The sender may ask again after a decline.
    assert send(sender, patient).status_code == 201


def test_asking_the_same_person_twice_returns_the_open_request(
    database_app, database, account
):
    requester, patient = account(), account()
    sender = Api(database_app, requester)

    first = send(sender, patient).json["request"]
    second = send(sender, patient).json["request"]

    assert first["id"] == second["id"]
    assert count(database, CareCircleCreationRequest) == 1


def test_sender_and_patient_can_cancel_an_open_request(
    database_app, database, account
):
    requester, patient = account(), account()
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    first = send(sender, patient).json["request"]["id"]
    assert sender.delete(f"{BASE}/{first}").status_code == 204
    assert sender.get(BASE).json["sent"] == []

    second = send(sender, patient).json["request"]["id"]
    assert receiver.delete(f"{BASE}/{second}").status_code == 204
    assert receiver.get(BASE).json["received"] == []
    assert receiver.delete(f"{BASE}/{second}").status_code == 204


def test_you_cannot_ask_for_a_circle_for_your_own_number(
    database_app, database, account
):
    me = account()

    response = send(Api(database_app, me), me)

    assert error_code(response, 422) == "self_request"


def test_a_person_who_already_has_a_circle_cannot_be_asked(
    database_app, database, account
):
    requester, patient = account(), account()
    Api(database_app, patient).post(
        "/api/v1/circles/self",
        {"name": "Mine", "birth_date": "1950-01-02", "city": "Riyadh"},
    )

    response = send(Api(database_app, requester), patient)

    assert error_code(response, 422) == "already_has_circle"


def test_an_incomplete_profile_cannot_send_a_request(
    database_app, database, account
):
    response = send(Api(database_app, account(complete=False)), account())

    assert error_code(response, 422) == "profile_incomplete"


def test_a_request_waits_for_a_person_who_signs_up_later(
    database_app, database, account
):
    sender = Api(database_app, account())
    future = "+966577777777"

    sent = sender.post(BASE, {"patient_phone_number": future, **REQUEST})
    assert sent.status_code == 201

    with Session(database, expire_on_commit=False) as session, session.begin():
        session.add(
            Account(
                phone_number=future,
                first_name="Late",
                last_name="Joiner",
                display_name="Late",
            )
        )
        late = session.scalar(
            select(Account).where(Account.phone_number == future)
        )
    received = Api(database_app, late).get(BASE).json["received"]
    assert [r["id"] for r in received] == [sent.json["request"]["id"]]
    assert received[0]["circle_name"] == "Mother Late"


@pytest.mark.parametrize("accept", [True, False])
def test_a_finished_request_cannot_be_answered_the_other_way(
    database_app, database, account, accept
):
    requester, patient = account(), account()
    sender, receiver = Api(database_app, requester), Api(database_app, patient)
    request_id = send(sender, patient).json["request"]["id"]
    receiver.post(f"{BASE}/{request_id}/respond", {"accept": accept})

    response = receiver.post(
        f"{BASE}/{request_id}/respond", {"accept": not accept}
    )

    assert error_code(response, 422) == "request_not_pending"
