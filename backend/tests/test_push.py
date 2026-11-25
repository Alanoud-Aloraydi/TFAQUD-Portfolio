"""Push notifications without a database: choosing the sender, OneSignal's
request and answers, and the scan command."""

import json

import httpx
import pytest

from app import create_app
from app.config import load_config
from app.config.values import ConfigError
from app.push import (
    NoPushSender,
    OneSignalPushSender,
    PushMessage,
    create_push_sender,
)
from app.push.sender import FAILED, NO_DEVICE, SENT

ACCOUNT = "6f1c2b9e-3a4d-4c5e-8f70-1a2b3c4d5e6f"
# The same account as the app gives it to OneSignal.login: the id the API
# answers has no dashes, and OneSignal matches it letter for letter.
APP_ACCOUNT = "6f1c2b9e3a4d4c5e8f701a2b3c4d5e6f"
MESSAGE = PushMessage("دعوة إلى دائرة رعاية", "دعوة من ريم.", "invitation")
SETTINGS = {
    "PUSH_BACKEND": "onesignal",
    "ONESIGNAL_APP_ID": "50e5581f-1938-47b7-a23a-c65c70c4a26d",
    "ONESIGNAL_API_KEY": "os_v2_app_test",
}


def onesignal(handler):
    return OneSignalPushSender(
        app_id=SETTINGS["ONESIGNAL_APP_ID"],
        api_key=SETTINGS["ONESIGNAL_API_KEY"],
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )


# ---- choosing the sender --------------------------------------------------


def test_nothing_is_sent_unless_set_up():
    sender = create_push_sender({"PUSH_BACKEND": "none"})
    assert isinstance(sender, NoPushSender)
    assert sender.enabled is False


def test_tests_never_use_onesignal(monkeypatch):
    monkeypatch.setenv("PUSH_BACKEND", "onesignal")
    assert load_config("testing")["PUSH_BACKEND"] == "none"


def test_an_unknown_backend_stops_the_app():
    with pytest.raises(ConfigError, match="PUSH_BACKEND"):
        create_push_sender({"PUSH_BACKEND": "firebase"})


def test_the_old_apple_setting_says_what_to_set_instead():
    with pytest.raises(ConfigError, match="onesignal"):
        create_push_sender({"PUSH_BACKEND": "apns"})


@pytest.mark.parametrize("missing", ["ONESIGNAL_APP_ID", "ONESIGNAL_API_KEY"])
def test_onesignal_needs_both_settings(missing):
    with pytest.raises(ConfigError, match=missing):
        create_push_sender({**SETTINGS, missing: None})


def test_onesignal_with_its_settings():
    assert isinstance(create_push_sender(SETTINGS), OneSignalPushSender)


def test_the_app_can_be_given_a_sender():
    from app.push import RecordingPushSender

    sender = RecordingPushSender()
    app = create_app("testing", push_sender=sender)
    assert app.extensions["push_sender"] is sender


# ---- OneSignal's request and answers ----------------------------------------


def test_the_request_onesignal_expects():
    seen = []

    def handler(request):
        seen.append(request)
        return httpx.Response(200, json={"id": "n-1"})

    assert onesignal(handler).send(ACCOUNT, MESSAGE) == SENT

    request = seen[0]
    assert str(request.url) == (
        "https://api.onesignal.com/notifications?c=push"
    )
    assert request.headers["authorization"] == "Key os_v2_app_test"
    assert json.loads(request.content) == {
        "app_id": SETTINGS["ONESIGNAL_APP_ID"],
        "target_channel": "push",
        "include_aliases": {"external_id": [APP_ACCOUNT]},
        "headings": {"en": MESSAGE.title, "ar": MESSAGE.title},
        "contents": {"en": MESSAGE.body, "ar": MESSAGE.body},
        "data": {"kind": "invitation"},
        "ios_sound": "tafaqod_chime.wav",
        "thread_id": "invitation",
        "android_group": "invitation",
        "ios_interruption_level": "active",
    }


def test_a_task_due_now_is_time_sensitive_and_a_request_is_not():
    """A missed or put-off task shows through a Focus on iOS; an
    invitation waits like any other notification."""
    sender = onesignal(lambda request: httpx.Response(200, json={"id": "n"}))
    for kind in ("dose_missed", "measurement_snoozed", "appointment_missed"):
        message = PushMessage("t", "b", kind)
        level = sender.payload(ACCOUNT, message)["ios_interruption_level"]
        assert level == "time_sensitive"
    assert sender.payload(ACCOUNT, MESSAGE)["ios_interruption_level"] == (
        "active"
    )


def test_a_reminder_stacks_by_circle_and_shows_its_button():
    """A reminder at a task's time stacks with its circle's, as the phone's
    own reminders do, and «ذكّرني لاحقًا» comes from the app's category."""
    sender = onesignal(lambda request: httpx.Response(200, json={"id": "n"}))
    message = PushMessage(
        "حان موعد الدواء", "…", "dose_reminder",
        thread="circle-1", category="tafaqod.reminder",
    )

    body = sender.payload(ACCOUNT, message)

    assert body["thread_id"] == body["android_group"] == "circle-1"
    assert body["ios_category"] == "tafaqod.reminder"
    assert body["ios_interruption_level"] == "time_sensitive"
    # Any other push has no buttons.
    assert "ios_category" not in sender.payload(ACCOUNT, MESSAGE)


def test_a_refused_interruption_level_never_loses_the_push():
    """OneSignal answered 400 to a level it did not know, and every missed
    push of a day was lost: the push now goes again without the level."""
    bodies = []

    def handler(request):
        body = json.loads(request.content)
        bodies.append(body)
        if "ios_interruption_level" in body:
            return httpx.Response(400, json={"errors": [
                "Ios interruption level iOS interruption level is invalid"
            ]})
        return httpx.Response(200, json={"id": "n-1"})

    message = PushMessage("جرعة فائتة", "…", "dose_missed")
    assert onesignal(handler).send(ACCOUNT, message) == SENT

    assert len(bodies) == 2
    assert "ios_interruption_level" not in bodies[1]
    assert bodies[1]["contents"] == bodies[0]["contents"]


def test_known_phones_are_sent_to_by_their_subscriptions():
    """The phones the account's sign-ins sent, the way OneSignal's own test
    message reaches them: an external id the app never tied reaches
    nothing."""
    seen = []

    def handler(request):
        seen.append(request)
        return httpx.Response(200, json={"id": "n-1"})

    phones = {
        "b2c3d4e5-0000-4000-8000-000000000002",
        "a1b2c3d4-0000-4000-8000-000000000001",
    }
    assert onesignal(handler).send(ACCOUNT, MESSAGE, phones) == SENT

    body = json.loads(seen[0].content)
    assert body["include_subscription_ids"] == sorted(phones)
    assert "include_aliases" not in body


def test_the_item_a_push_is_about_goes_beside_its_kind():
    seen = []

    def handler(request):
        seen.append(request)
        return httpx.Response(200, json={"id": "n-1"})

    message = PushMessage(
        "جرعة فائتة",
        "فات موعد جرعة.",
        "dose_missed",
        (
            ("circle_id", "c-1"),
            ("schedule_id", "s-1"),
            ("scheduled_on", "2026-11-15"),
        ),
    )
    onesignal(handler).send(ACCOUNT, message)

    assert json.loads(seen[0].content)["data"] == {
        "kind": "dose_missed",
        "circle_id": "c-1",
        "schedule_id": "s-1",
        "scheduled_on": "2026-11-15",
    }


@pytest.mark.parametrize(
    ("status", "answer", "result"),
    [
        # No phone of the account shows pushes: not a failure.
        (
            200,
            {"id": "", "errors": ["All included players are not subscribed"]},
            NO_DEVICE,
        ),
        (200, {"errors": {"invalid_aliases": {"external_id": [ACCOUNT]}}},
         NO_DEVICE),
        (400, {"errors": ["app_id not found"]}, FAILED),
        (403, {"errors": ["Access denied"]}, FAILED),
        (500, {}, FAILED),
    ],
)
def test_onesignals_answers(status, answer, result):
    def handler(request):
        return httpx.Response(status, json=answer)

    assert onesignal(handler).send(ACCOUNT, MESSAGE) == result


def test_onesignal_out_of_reach():
    def handler(request):
        raise httpx.ConnectError("no route")

    assert onesignal(handler).send(ACCOUNT, MESSAGE) == FAILED


# ---- a sick OneSignal -------------------------------------------------------


def test_after_three_failures_onesignal_is_not_called_for_a_while():
    calls = []

    def handler(request):
        calls.append(request)
        if len(calls) == 1:
            raise httpx.ConnectError("no route")
        return httpx.Response(503, json={})

    sender = onesignal(handler)
    for _ in range(3):
        assert sender.send(ACCOUNT, MESSAGE) == FAILED

    # Answered at once.
    assert sender.send(ACCOUNT, MESSAGE) == FAILED
    assert len(calls) == 3


def test_an_answer_about_one_account_opens_nothing():
    calls = []

    def handler(request):
        calls.append(request)
        return httpx.Response(200, json={"id": "", "errors": ["x"]})

    sender = onesignal(handler)
    for _ in range(4):
        assert sender.send(ACCOUNT, MESSAGE) == NO_DEVICE

    assert len(calls) == 4


# ---- phones whose app was deleted -------------------------------------------


def test_onesignal_reports_the_phones_whose_app_was_deleted():
    seen = []

    def handler(request):
        seen.append(request)
        return httpx.Response(200, json={
            "identity": {"external_id": APP_ACCOUNT},
            "subscriptions": [
                {"id": "gone", "type": "iOSPush", "notification_types": -10},
                # Notifications turned off: the app is still there.
                {"id": "off", "type": "AndroidPush", "notification_types": 0},
                {"id": "out", "type": "iOSPush", "notification_types": -2},
                {"id": "on", "type": "AndroidPush", "notification_types": 1},
                {"type": "iOSPush", "notification_types": -10},
            ],
        })

    deleted = onesignal(handler).deleted_apps(ACCOUNT)

    assert deleted == {"gone"}
    [request] = seen
    assert request.method == "GET"
    assert str(request.url) == (
        "https://api.onesignal.com/apps/"
        f"{SETTINGS['ONESIGNAL_APP_ID']}/users/by/external_id/{APP_ACCOUNT}"
    )
    assert request.headers["Authorization"] == "Key os_v2_app_test"


@pytest.mark.parametrize(
    "status, body",
    [
        (404, {"errors": ["User not found"]}),
        (401, {"errors": ["Access denied"]}),
        (503, {}),
        (200, {"subscriptions": "nothing"}),
        (200, ["not", "an", "object"]),
    ],
)
def test_any_doubt_reports_no_deleted_app(status, body):
    sender = onesignal(lambda request: httpx.Response(status, json=body))

    assert sender.deleted_apps(ACCOUNT) == set()


def test_out_of_reach_reports_no_deleted_app():
    def handler(request):
        raise httpx.ConnectError("no route")

    assert onesignal(handler).deleted_apps(ACCOUNT) == set()


def test_without_a_push_service_no_app_is_deleted():
    assert NoPushSender().deleted_apps(ACCOUNT) == set()


# ---- the scan command -------------------------------------------------------


def test_the_scan_command_needs_the_database():
    app = create_app("testing")
    result = app.test_cli_runner().invoke(args=["tick"])
    # Without a database the command is not there at all.
    assert result.exit_code != 0
