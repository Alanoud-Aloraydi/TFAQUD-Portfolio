"""Push notifications without a database: choosing the sender, Apple's
request, and checking the token the app sends."""

import json

import httpx
import jwt
import pytest
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import ec

from app import create_app
from app.config import ConfigError, load_config
from app.push import (
    ApnsPushSender,
    NoPushSender,
    PushMessage,
    create_push_sender,
)
from app.push.sender import FAILED, GONE, SENT, UNREGISTERED
from tests.conftest import bearer

TOKEN = "ab" * 32
MESSAGE = PushMessage("دعوة إلى دائرة رعاية", "دعوة من ريم.", "invitation")


@pytest.fixture
def key():
    return ec.generate_private_key(ec.SECP256R1())


def pem(key) -> str:
    return key.private_bytes(
        serialization.Encoding.PEM,
        serialization.PrivateFormat.PKCS8,
        serialization.NoEncryption(),
    ).decode()


def apns(key, handler, environment="sandbox"):
    return ApnsPushSender(
        key_id="KEY1234567",
        team_id="TEAM123456",
        bundle_id="com.tafaqod.app",
        private_key=pem(key),
        environment=environment,
        client=httpx.Client(transport=httpx.MockTransport(handler)),
    )


# ---- choosing the sender --------------------------------------------------


def test_nothing_is_sent_unless_set_up():
    sender = create_push_sender({"PUSH_BACKEND": "none"})
    assert isinstance(sender, NoPushSender)
    assert sender.enabled is False


def test_tests_never_use_apple(monkeypatch):
    monkeypatch.setenv("PUSH_BACKEND", "apns")
    assert load_config("testing")["PUSH_BACKEND"] == "none"


def test_an_unknown_backend_stops_the_app():
    with pytest.raises(ConfigError, match="PUSH_BACKEND"):
        create_push_sender({"PUSH_BACKEND": "firebase"})


def test_apple_needs_every_setting():
    with pytest.raises(ConfigError, match="APNS_KEY_ID"):
        create_push_sender(
            {
                "PUSH_BACKEND": "apns",
                "APNS_TEAM_ID": "TEAM123456",
                "APNS_BUNDLE_ID": "com.tafaqod.app",
                "APNS_PRIVATE_KEY_PATH": "/nowhere/AuthKey.p8",
            }
        )


def test_apple_with_its_key(tmp_path, key):
    path = tmp_path / "AuthKey_KEY1234567.p8"
    path.write_text(pem(key))
    config = {
        "PUSH_BACKEND": "apns",
        "APNS_KEY_ID": "KEY1234567",
        "APNS_TEAM_ID": "TEAM123456",
        "APNS_BUNDLE_ID": "com.tafaqod.app",
        "APNS_PRIVATE_KEY_PATH": str(path),
        "APNS_ENVIRONMENT": "production",
    }
    assert isinstance(create_push_sender(config), ApnsPushSender)

    with pytest.raises(ConfigError, match="cannot be read"):
        create_push_sender({**config, "APNS_PRIVATE_KEY_PATH": "/nowhere"})
    with pytest.raises(ConfigError, match="APNS_ENVIRONMENT"):
        create_push_sender({**config, "APNS_ENVIRONMENT": "test"})


# ---- Apple's request ------------------------------------------------------


def test_the_request_apple_expects(key):
    seen = []

    def handler(request):
        seen.append(request)
        return httpx.Response(200)

    assert apns(key, handler).send(TOKEN, MESSAGE) == SENT

    request = seen[0]
    assert str(request.url) == (
        f"https://api.sandbox.push.apple.com/3/device/{TOKEN}"
    )
    assert request.headers["apns-topic"] == "com.tafaqod.app"
    assert request.headers["apns-push-type"] == "alert"
    assert request.headers["apns-priority"] == "10"
    scheme, _, token = request.headers["authorization"].partition(" ")
    assert scheme == "bearer"
    assert jwt.get_unverified_header(token) == {
        "alg": "ES256",
        "kid": "KEY1234567",
        "typ": "JWT",
    }
    claims = jwt.decode(token, key.public_key(), algorithms=["ES256"])
    assert claims["iss"] == "TEAM123456"
    assert json.loads(request.content) == {
        "aps": {
            "alert": {"title": MESSAGE.title, "body": MESSAGE.body},
            "sound": "tafaqod_chime.wav",
            "thread-id": "invitation",
        },
        "kind": "invitation",
    }


def test_production_goes_to_apples_main_server(key):
    hosts = []

    def handler(request):
        hosts.append(request.url.host)
        return httpx.Response(200)

    apns(key, handler, "production").send(TOKEN, MESSAGE)
    assert hosts == ["api.push.apple.com"]


def test_the_provider_token_is_reused(key):
    tokens = []

    def handler(request):
        tokens.append(request.headers["authorization"])
        return httpx.Response(200)

    sender = apns(key, handler)
    sender.send(TOKEN, MESSAGE)
    sender.send(TOKEN, MESSAGE)
    assert tokens[0] == tokens[1]


@pytest.mark.parametrize(
    ("status", "reason", "result"),
    [
        (410, "Unregistered", UNREGISTERED),
        (410, "ExpiredToken", UNREGISTERED),
        # Often a sandbox token sent to the production server: the app may
        # well still be on the phone.
        (400, "BadDeviceToken", GONE),
        (400, "DeviceTokenNotForTopic", GONE),
        (403, "InvalidProviderToken", FAILED),
        (500, "InternalServerError", FAILED),
    ],
)
def test_apples_answers(key, status, reason, result):
    def handler(request):
        return httpx.Response(status, json={"reason": reason})

    assert apns(key, handler).send(TOKEN, MESSAGE) == result


def test_apple_out_of_reach(key):
    def handler(request):
        raise httpx.ConnectError("no route")

    assert apns(key, handler).send(TOKEN, MESSAGE) == FAILED


# ---- the token the app sends ----------------------------------------------

URL = "/api/v1/accounts/me/push-device"


def test_registering_needs_a_sign_in(client):
    response = client.put(URL, json={"token": TOKEN})
    assert response.status_code == 401


@pytest.mark.parametrize(
    "token", ["", "xyz", "ab" * 31, "ab" * 101, "ab" * 31 + "a g"]
)
def test_a_token_that_is_not_apples_is_refused(client, signed_in, token):
    response = client.put(
        URL, json={"token": token}, headers=bearer(signed_in.access_token)
    )
    assert response.status_code == 422


def test_without_a_database_the_token_cannot_be_kept(client, signed_in):
    response = client.put(
        URL, json={"token": TOKEN}, headers=bearer(signed_in.access_token)
    )
    assert response.status_code == 503


def test_the_app_can_be_given_a_sender():
    from app.push import RecordingPushSender

    sender = RecordingPushSender()
    app = create_app("testing", push_sender=sender)
    assert app.extensions["push_sender"] is sender


# ---- a sick Apple -----------------------------------------------------------


def test_after_three_failures_apple_is_not_called_for_a_while(key):
    calls = []

    def handler(request):
        calls.append(request)
        if len(calls) == 1:
            raise httpx.ConnectError("no route")
        return httpx.Response(503, json={"reason": "ServiceUnavailable"})

    sender = apns(key, handler)
    for _ in range(3):
        assert sender.send(TOKEN, MESSAGE) == FAILED

    # Answered at once; the token is kept for the next time.
    assert sender.send(TOKEN, MESSAGE) == FAILED
    assert len(calls) == 3


def test_an_answer_about_one_phone_opens_nothing(key):
    calls = []

    def handler(request):
        calls.append(request)
        return httpx.Response(410, json={"reason": "Unregistered"})

    sender = apns(key, handler)
    for _ in range(4):
        assert sender.send(TOKEN, MESSAGE) == UNREGISTERED

    assert len(calls) == 4
