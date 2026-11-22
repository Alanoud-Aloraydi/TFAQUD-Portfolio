"""Push notifications on PostgreSQL: who is told about invitations and
circle requests. OneSignal knows each phone by its signed-in account, so a
push goes to an account that is signed in somewhere. Each sign-in keeps its
phone's OneSignal subscription, and a phone whose app was deleted is signed
out."""

import uuid

import pytest
from sqlalchemy import select
from sqlalchemy.orm import Session

from app import metrics
from app.models import AccountSession
from app.push import NoPushSender, RecordingPushSender
from integration_tests.helpers import offline_circle

SUBSCRIPTION = "/api/v1/accounts/me/push-subscription"

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

    def subscribe(self, subscription=None, server_reminders=None):
        """What the app does after signing in: send its phone's OneSignal
        subscription (a new one unless given), and, from the app that asks
        for them, `server_reminders`. The server's answer is kept in
        `answer`."""
        self.subscription = subscription or str(uuid.uuid4())
        body = {"subscription_id": self.subscription}
        if server_reminders is not None:
            body["server_reminders"] = server_reminders
        answer = self.call("put", SUBSCRIPTION, body)
        assert answer.status_code == 200, answer.json
        self.answer = answer.json
        return self

    def signed_in(self):
        return self.call("get", "/api/v1/auth/session").status_code == 200


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
    invitation_id = sent.json["invitation"]["id"]
    assert message.target == (("invitation_id", invitation_id),)
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
    assert asked.body == "وصلك طلب من Reem لمتابعة رعايتك في تفقُد."

    request_id = sent.json["request"]["id"]
    assert asked.target == (("request_id", request_id),)
    noura_phone.call(
        "post", f"{REQUESTS}/{request_id}/respond", {"accept": True}
    )
    [answered] = pushes.to(reem_phone.token)
    assert answered.kind == "request_answer"
    # Accepted, it waits for Noura: no card of the bell to open yet.
    assert answered.target == ()
    assert answered.title == "تم قبول طلبك"
    assert answered.body == (
        "تم قبول طلبك لرعاية Noura. تجهز الدائرة فور اكتمال البيانات."
    )

    done = noura_phone.call(
        "post", f"{REQUESTS}/{request_id}/complete", {**BASICS, "name": "صحتي"}
    )
    assert done.status_code == 201
    ready = pushes.to(reem_phone.token)[-1]
    assert ready.kind == "circle_ready"
    circle_id = done.json["circle"]["id"]
    assert ready.target == (("circle_id", circle_id),)
    # Reem is told the name she sees, not Noura's own «صحتي».
    assert ready.body == "«دائرة Noura» جاهزة، ويمكنك متابعة الرعاية الآن."


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
    # Declined, it is on Reem's bell: a tap opens it there.
    assert answer.target == (("request_id", sent.json["request"]["id"]),)


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


# ---- each sign-in's phone, and a deleted app --------------------------------


def _subscriptions(engine):
    with Session(engine) as session:
        return {
            row.id.hex: row.push_subscription_id
            for row in session.scalars(select(AccountSession))
        }


def test_a_sign_in_keeps_its_phones_subscription(
    database_app, database, account
):
    phone = Phone(database_app, account(), "b").subscribe()

    kept = _subscriptions(database)[phone.issued.session_id]

    assert str(kept) == phone.subscription
    # A new one (OneSignal gave the phone another) takes its place.
    phone.subscribe()
    assert str(
        _subscriptions(database)[phone.issued.session_id]
    ) == phone.subscription


def test_a_phone_signed_in_again_moves_its_subscription(
    database_app, database, account
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    before = Phone(database_app, reem, "b").subscribe()
    before.sign_out()

    after = Phone(database_app, khaled, "c").subscribe(before.subscription)

    kept = _subscriptions(database)
    assert kept[before.issued.session_id] is None
    assert str(kept[after.issued.session_id]) == before.subscription


@pytest.mark.parametrize(
    "body", [{}, {"subscription_id": "not-an-id"}, {"other": 1}]
)
def test_the_subscription_must_be_an_id(database_app, database, account, body):
    phone = Phone(database_app, account(), "b")

    answer = phone.call("put", SUBSCRIPTION, body)

    assert answer.status_code == 422


def test_the_subscription_needs_a_sign_in(database_app, database):
    answer = database_app.test_client().put(
        SUBSCRIPTION, json={"subscription_id": str(uuid.uuid4())}
    )

    assert answer.status_code == 401


def test_a_deleted_app_signs_its_phone_out(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    deleted = Phone(database_app, khaled, "b").subscribe()
    kept = Phone(database_app, khaled, "d").subscribe()
    pushes.deleted[str(khaled.id)] = {deleted.subscription}

    assert invite(database_app, database, reem, khaled).status_code == 201

    assert not deleted.signed_in()
    assert kept.signed_in()
    assert metrics.count("session.signed_out_app_deleted") == 1
    # Told once, before the sign-out.
    assert len(pushes.to(khaled.id)) == 1


def test_a_push_goes_to_each_signed_in_phone(
    database_app, database, account, pushes
):
    """To the subscriptions the sign-ins sent: OneSignal's external id is
    only the fallback, as it reaches nothing when the app's login did not
    take."""
    reem, khaled = account(name="Reem"), account(name="Khaled")
    one = Phone(database_app, khaled, "b").subscribe()
    two = Phone(database_app, khaled, "d").subscribe()

    invite(database_app, database, reem, khaled)

    assert pushes.phones[str(khaled.id)] == {
        one.subscription,
        two.subscription,
    }


def test_a_phone_with_notifications_off_stays_signed_in(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    phone = Phone(database_app, khaled, "b").subscribe()
    # OneSignal can show it nothing, but its app is there.
    pushes.no_device.add(str(khaled.id))

    invite(database_app, database, reem, khaled)

    assert pushes.asked == [str(khaled.id)]
    assert phone.signed_in()


def test_a_deleted_app_on_a_phone_unknown_here_ends_nothing(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    phone = Phone(database_app, khaled, "b").subscribe()
    # Another phone of Khaled's, whose sign-in never sent its subscription.
    pushes.deleted[str(khaled.id)] = {str(uuid.uuid4())}

    invite(database_app, database, reem, khaled)

    assert phone.signed_in()
    assert metrics.count("session.signed_out_app_deleted") == 0


def test_an_account_without_a_known_phone_is_not_asked(
    database_app, database, account, pushes
):
    reem, khaled = account(name="Reem"), account(name="Khaled")
    Phone(database_app, khaled, "b")

    invite(database_app, database, reem, khaled)

    assert len(pushes.to(khaled.id)) == 1
    assert pushes.asked == []
