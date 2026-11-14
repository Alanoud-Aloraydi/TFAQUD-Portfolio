"""Push notifications on PostgreSQL: who is told about invitations and
circle requests. OneSignal knows each phone by its signed-in account, so a
push goes to an account that is signed in somewhere."""

import pytest

from app.push import NoPushSender, RecordingPushSender
from integration_tests.helpers import offline_circle

REQUESTS = "/api/v1/circle-requests"
REQUEST = {"proposed_app_mode": "simplified"}
BASICS = {"birth_date": "1950-01-02", "city": "Buraydah"}


class Phone:
    """One signed-in phone of an account: its own session. `token` is what
    the server sends to, the account's id (OneSignal's external id)."""

    def __init__(self, app, account, digit=None):
        self.issued = app.extensions["session_service"].create_session(
            account.id.hex
        )
        self.app = app
        self.client = app.test_client()
        self.headers = {
            "Authorization": "Bearer " + self.issued.access_token
        }
        self.account = account
        self.token = str(account.id)

    def call(self, method, url, body=None):
        return getattr(self.client, method)(
            url, json=body, headers=self.headers
        )

    def sign_out(self):
        self.app.extensions["session_service"].sign_out(
            self.issued.session_id
        )


@pytest.fixture
def pushes(database_app, monkeypatch):
    """What would reach OneSignal, kept for the test."""
    sender = RecordingPushSender()
    monkeypatch.setitem(database_app.extensions, "push_sender", sender)
    return sender


def test_an_invitation_reaches_the_invited_phone(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)
    khaled_phone = Phone(database_app, khaled, "b")
    reem_phone = Phone(database_app, reem, "c")

    sent = reem_phone.call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert sent.status_code == 201
    [message] = pushes.to(khaled_phone.token)
    assert message.kind == "invitation"
    assert message.title == "دعوة لدائرة رعاية"
    # As Khaled sees the circle: «دائرة» and the patient's first name.
    assert message.body == "وصلتك دعوة من Reem للانضمام إلى «دائرة Nora»."
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


def test_an_account_signed_out_everywhere_is_not_told(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    gone = Phone(database_app, khaled, "b")
    gone.sign_out()

    assert invite(database_app, database, reem, khaled).status_code == 201

    assert pushes.to(gone.token) == []


def test_an_account_signed_in_on_another_phone_is_told(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    old = Phone(database_app, khaled, "b")
    old.sign_out()
    new = Phone(database_app, khaled, "d")

    invite(database_app, database, reem, khaled)

    # One push to the account; OneSignal shows it on the phones signed in.
    assert len(pushes.to(new.token)) == 1


def test_an_account_whose_phones_show_no_push_is_counted_not_failed(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    phone = Phone(database_app, khaled, "b")
    pushes.no_device.add(phone.token)

    assert invite(database_app, database, reem, khaled).status_code == 201

    assert pushes.sent == []


def test_a_circle_request_from_sending_to_the_circle(
    database_app, database, account, pushes
):
    reem, noura = account(name="Reem"), account(name="Noura")
    reem_phone, noura_phone = (
        Phone(database_app, reem, "c"),
        Phone(database_app, noura, "e"),
    )

    sent = reem_phone.call(
        "post",
        REQUESTS,
        {"patient_phone_number": noura.phone_number, **REQUEST},
    )
    [asked] = pushes.to(noura_phone.token)
    assert asked.kind == "circle_request"
    assert asked.body == "وصلك طلب من Reem لمتابعة رعايتك في تفقّد."

    request_id = sent.json["request"]["id"]
    noura_phone.call(
        "post", f"{REQUESTS}/{request_id}/respond", {"accept": True}
    )
    [answered] = pushes.to(reem_phone.token)
    assert answered.kind == "request_answer"
    assert answered.title == "تم قبول طلبك"
    assert answered.body == (
        "تم قبول طلبك لرعاية Noura. الدائرة تجهز أول ما تكتمل البيانات."
    )

    done = noura_phone.call(
        "post", f"{REQUESTS}/{request_id}/complete", {**BASICS, "name": "صحتي"}
    )
    assert done.status_code == 201
    ready = pushes.to(reem_phone.token)[-1]
    assert ready.kind == "circle_ready"
    # Reem is told the name she sees, not Noura's own «صحتي».
    assert ready.body == "«دائرة Noura» جاهزة، وتقدر تتابع الرعاية الحين."


def test_a_declined_request_is_told(database_app, database, account, pushes):
    reem, noura = account(name="Reem"), account(name="Noura")
    reem_phone = Phone(database_app, reem, "c")
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
    assert answer.title == "تم الاعتذار عن طلبك"
    assert answer.body == "تم الاعتذار عن طلبك لرعاية Noura."


def invite(database_app, database, inviter, invited):
    """`inviter` invites `invited`'s number to a new circle: a push to every
    signed-in phone of `invited`."""
    circle = offline_circle(database, inviter)
    return Phone(database_app, inviter, "c").call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": invited.phone_number},
    )


def test_without_a_push_service_the_request_still_works(
    database_app, database, account, monkeypatch
):
    monkeypatch.setitem(
        database_app.extensions, "push_sender", NoPushSender()
    )
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)

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
        def send(self, account_id, message):
            raise RuntimeError("OneSignal is down")

    monkeypatch.setitem(database_app.extensions, "push_sender", Broken())
    reem, khaled = account(name="Reem"), account(name="Khaled")
    circle = offline_circle(database, reem)

    sent = Phone(database_app, reem, "c").call(
        "post",
        f"/api/v1/circles/{circle.id}/invitations",
        {"invitee_phone_number": khaled.phone_number},
    )

    assert sent.status_code == 201
