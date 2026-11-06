"""Push notifications on PostgreSQL: the phone's token, and who is told
about invitations and circle requests."""

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import PushDevice
from app.push import NoPushSender, RecordingPushSender
from integration_tests.helpers import offline_circle

DEVICE = "/api/v1/accounts/me/push-device"
REQUESTS = "/api/v1/circle-requests"
REQUEST = {"circle_label": "Mother", "proposed_app_mode": "simplified"}
BASICS = {"birth_date": "1950-01-02", "city": "Buraydah"}


class Phone:
    """One signed-in phone of an account: its own session and push token."""

    def __init__(self, app, account, token_digit):
        self.issued = app.extensions["session_service"].create_session(
            account.id.hex
        )
        self.app = app
        self.client = app.test_client()
        self.headers = {
            "Authorization": "Bearer " + self.issued.access_token
        }
        self.account = account
        self.token = token_digit * 64

    def call(self, method, url, body=None):
        return getattr(self.client, method)(
            url, json=body, headers=self.headers
        )

    def register(self, token=None):
        return self.call("put", DEVICE, {"token": token or self.token})

    def sign_out(self):
        self.app.extensions["session_service"].sign_out(
            self.issued.session_id
        )


@pytest.fixture
def pushes(database_app, monkeypatch):
    """What would reach Apple, kept for the test."""
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return sender


def devices(database):
    with Session(database) as session:
        return {
            row.token: row
            for row in session.scalars(select(PushDevice)).all()
        }


def test_a_phone_registers_its_token(database_app, database, account):
    reem = account(name="Reem")
    phone = Phone(database_app, reem, "a")

    response = phone.register()

    assert response.status_code == 204
    row = devices(database)[phone.token]
    assert row.account_id == reem.id
    assert row.session_id.hex == phone.issued.session_id.replace("-", "")
    # Upper case is the same token.
    assert phone.register(phone.token.upper()).status_code == 204
    assert list(devices(database)) == [phone.token]


def test_a_token_moves_with_the_phone(database_app, database, account):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    Phone(database_app, reem, "a").register()

    Phone(database_app, khaled, "a").register()

    assert devices(database)["a" * 64].account_id == khaled.id


def test_an_invitation_reaches_the_invited_phone(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    khaled_phone = Phone(database_app, khaled, "b")
    khaled_phone.register()
    reem_phone = Phone(database_app, reem, "c")
    reem_phone.register()

    sent = reem_phone.call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert sent.status_code == 201
    [message] = pushes.to(khaled_phone.token)
    assert message.kind == "invitation"
    assert message.title == "دعوة إلى دائرة رعاية"
    # As Khaled sees the circle: «دائرة» and the patient's first name.
    assert message.body == "دعوة من Reem للانضمام إلى «دائرة Nora»."
    assert pushes.to(reem_phone.token) == []

    # Sent again: told again.
    invitation_id = sent.json["invitation"]["id"]
    reem_phone.call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations/{invitation_id}/resend",
    )
    assert len(pushes.to(khaled_phone.token)) == 2


def test_a_number_without_the_app_gets_no_push(
    database_app, database, account, pushes
):
    reem = account(name="Reem")
    circle = offline_circle(database, reem)
    phone = Phone(database_app, reem, "c")

    sent = phone.call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": "+966599999999"},
    )

    assert sent.status_code == 201
    assert pushes.sent == []


def test_a_signed_out_phone_is_not_told(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    old = Phone(database_app, khaled, "b")
    old.register()
    old.sign_out()
    new = Phone(database_app, khaled, "d")
    new.register()

    Phone(database_app, reem, "c").call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert pushes.to(old.token) == []
    assert len(pushes.to(new.token)) == 1


def test_a_circle_request_from_sending_to_the_circle(
    database_app, database, account, pushes
):
    reem, noura = account(name="Reem"), account(name="Noura")
    reem_phone, noura_phone = (
        Phone(database_app, reem, "c"),
        Phone(database_app, noura, "e"),
    )
    reem_phone.register()
    noura_phone.register()

    sent = reem_phone.call(
        "post",
        REQUESTS,
        {"patient_phone_number": noura.phone_number, **REQUEST},
    )
    [asked] = pushes.to(noura_phone.token)
    assert asked.kind == "circle_request"
    assert asked.body == "طلب من Reem لمتابعة رعايتك في تفقّد."

    request_id = sent.json["request"]["id"]
    noura_phone.call(
        "post", f"{REQUESTS}/{request_id}/respond", {"accept": True}
    )
    [answered] = pushes.to(reem_phone.token)
    assert answered.kind == "request_answer"
    assert answered.title == "تمت الموافقة على طلبك"
    assert answered.body == (
        "تمت الموافقة على طلبك لرعاية Noura. تُنشأ الدائرة بعد إكمال البيانات."
    )

    done = noura_phone.call(
        "post", f"{REQUESTS}/{request_id}/complete", {**BASICS, "name": "صحتي"}
    )
    assert done.status_code == 201
    ready = pushes.to(reem_phone.token)[-1]
    assert ready.kind == "circle_ready"
    # Reem is told the name she sees, not Noura's own «صحتي».
    assert ready.body == "أُنشئت «دائرة Noura»، ويمكنك متابعة الرعاية الآن."


def test_a_declined_request_is_told(database_app, database, account, pushes):
    reem, noura = account(name="Reem"), account(name="Noura")
    reem_phone = Phone(database_app, reem, "c")
    reem_phone.register()
    sent = reem_phone.call(
        "post",
        REQUESTS,
        {"patient_phone_number": noura.phone_number, **REQUEST},
    )

    Phone(database_app, noura, "e").call(
        "post",
        f"{REQUESTS}/{sent.json['request']['id']}/respond",
        {"accept": False},
    )

    [answer] = pushes.to(reem_phone.token)
    assert answer.title == "اعتذار عن طلب الرعاية"
    assert answer.body == "لم تتم الموافقة على طلبك لرعاية Noura."


def test_a_token_apple_forgot_is_deleted(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    phone = Phone(database_app, khaled, "b")
    phone.register()
    pushes.gone.add(phone.token)

    Phone(database_app, reem, "c").call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert devices(database) == {}


def test_without_a_push_service_the_request_still_works(
    database_app, database, account, monkeypatch
):
    monkeypatch.setitem(
        database_app.extensions, "push_sender", NoPushSender()
    )
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    Phone(database_app, khaled, "b").register()

    sent = Phone(database_app, reem, "c").call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert sent.status_code == 201


def test_a_broken_push_never_breaks_the_request(
    database_app, database, account, monkeypatch
):
    class Broken(RecordingPushSender):
        def send(self, token, message):
            raise RuntimeError("Apple is down")

    monkeypatch.setitem(database_app.extensions, "push_sender", Broken())
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    Phone(database_app, khaled, "b").register()

    sent = Phone(database_app, reem, "c").call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert sent.status_code == 201


def test_deleting_the_account_deletes_its_tokens(
    database_app, database, account
):
    reem = account(name="Reem")
    phone = Phone(database_app, reem, "a")
    phone.register()

    response = phone.call("delete", "/api/v1/accounts/me", {})

    assert response.status_code in (200, 204)
    assert devices(database) == {}
