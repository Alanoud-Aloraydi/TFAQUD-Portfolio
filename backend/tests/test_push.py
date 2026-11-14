"""Push notifications without a database: choosing the sender, OneSignal's
request and answers, and the scan command."""

import json

import httpx
import pytest

from app import create_app
from app.config import ConfigError, load_config
from app.push import (
    NoPushSender,
    OneSignalPushSender,
    PushMessage,
    create_push_sender,
)
from app.push.sender import FAILED, NO_DEVICE, SENT

ACCOUNT = "6f1c2b9e-3a4d-4c5e-8f70-1a2b3c4d5e6f"
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
        "include_aliases": {"external_id": [ACCOUNT]},
        "headings": {"en": MESSAGE.title, "ar": MESSAGE.title},
        "contents": {"en": MESSAGE.body, "ar": MESSAGE.body},
        "data": {"kind": "invitation"},
        "ios_sound": "tafaqod_chime.wav",
        "thread_id": "invitation",
        "android_group": "invitation",
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


# ---- the scan command -------------------------------------------------------


def test_the_scan_command_needs_the_database():
    app = create_app("testing")
    result = app.test_cli_runner().invoke(args=["tick"])
    # Without a database the command is not there at all.
    assert result.exit_code != 0
