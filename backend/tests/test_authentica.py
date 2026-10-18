"""The Authentica sender. No test opens a network connection.

The answers below are the ones recorded in docs/api-contracts.md, section 8. A fake
`transport` plays Authentica and keeps every call, so a test can read what would
have been sent.
"""

import http.client
import io
import json
import urllib.error

import pytest

from app.config import ConfigError
from app.sms import authentica
from app.sms.authentica import AuthenticaSmsSender, urllib_post
from app.sms.base import SmsDeliveryError

KEY = "test-key-0123456789-abcdef"
PHONE = "+966500000001"
CODE = "482915"

SEND_OK = (200, {"success": True, "data": None, "message": "OTP sent successfully."})
VERIFY_OK = (200, {"status": True, "message": "OTP verified successfully"})
VERIFY_REFUSED = (422, {"status": False, "message": "Failed to verify OTP"})
WRONG_KEY = (401, {"errors": [{"message": "Unauthorized"}]})


class FakeTransport:
    """Plays Authentica: returns the prepared answers, one per call, in order."""

    def __init__(self, *answers):
        self._answers = list(answers)
        self.calls = []

    def __call__(self, url, headers, body, timeout):
        self.calls.append({"url": url, "headers": headers, "body": body, "timeout": timeout})
        answer = self._answers.pop(0)
        if isinstance(answer, BaseException):
            raise answer
        return answer


def make_sender(*answers, **kwargs):
    transport = FakeTransport(*answers)
    return AuthenticaSmsSender(KEY, transport=transport, **kwargs), transport


# --- send_code ---------------------------------------------------------------------


def test_send_code_asks_for_template_5_by_sms_and_sends_no_code_of_its_own():
    sender, transport = make_sender(SEND_OK)

    sender.send_code(PHONE)

    (call,) = transport.calls
    assert call["url"] == "https://api.authentica.sa/api/v2/send-otp"
    assert call["headers"] == {"X-Authorization": KEY}
    assert call["body"] == {"method": "sms", "phone": PHONE, "template_id": 5}
    assert "otp" not in call["body"]  # Authentica makes the code


def test_the_template_can_be_changed():
    sender, transport = make_sender(SEND_OK, template_id=31)

    sender.send_code(PHONE)

    assert transport.calls[0]["body"]["template_id"] == 31


@pytest.mark.parametrize(
    "answer",
    [
        WRONG_KEY,
        (429, {"message": "Too Many Attempts."}),
        (500, None),
        (200, {"success": False}),
        (200, {"status": True}),  # the field of verify-otp, not of send-otp
        (200, None),
        (422, {"message": "The phone field is invalid."}),
    ],
)
def test_send_code_raises_when_authentica_does_not_confirm(answer):
    sender, _ = make_sender(answer)

    with pytest.raises(SmsDeliveryError) as problem:
        sender.send_code(PHONE)

    assert problem.value.status == answer[0]
    assert KEY not in str(problem.value) and PHONE not in str(problem.value)


def test_a_wrong_key_says_where_to_look():
    sender, _ = make_sender(WRONG_KEY)

    with pytest.raises(SmsDeliveryError, match="AUTHENTICA_API_KEY"):
        sender.send_code(PHONE)


# --- check_code ----------------------------------------------------------------------


def test_check_code_sends_the_phone_and_the_code_to_verify_otp():
    sender, transport = make_sender(VERIFY_OK)

    assert sender.check_code(PHONE, CODE) is True

    (call,) = transport.calls
    assert call["url"] == "https://api.authentica.sa/api/v2/verify-otp"
    assert call["headers"] == {"X-Authorization": KEY}
    assert call["body"] == {"phone": PHONE, "otp": CODE}


def test_a_refused_code_is_false_whatever_the_reason():
    # Wrong, wrong length, expired and used all get this one answer.
    sender, _ = make_sender(VERIFY_REFUSED, VERIFY_REFUSED, VERIFY_REFUSED)

    assert [sender.check_code(PHONE, c) for c in ("000000", "123", CODE)] == [False] * 3


def test_a_refusal_is_decided_by_the_status_even_if_the_body_cannot_be_read():
    sender, _ = make_sender((422, None))

    assert sender.check_code(PHONE, CODE) is False


def test_status_false_with_http_200_is_a_refusal_too():
    sender, _ = make_sender((200, {"status": False}))

    assert sender.check_code(PHONE, CODE) is False


@pytest.mark.parametrize(
    "answer",
    [
        (200, {"verified": True}),  # a field of the vendor's examples, not the real one
        (200, {"success": True}),
        (200, {"status": "true"}),
        (200, {}),
        (200, None),
        (204, None),
    ],
)
def test_an_answer_we_do_not_know_never_grants_access(answer):
    sender, _ = make_sender(answer)

    with pytest.raises(SmsDeliveryError):
        sender.check_code(PHONE, CODE)


@pytest.mark.parametrize("answer", [WRONG_KEY, (429, None), (500, None), (503, None)])
def test_a_failure_of_the_provider_is_an_error_and_not_a_wrong_code(answer):
    # If it were False, the user would lose one of the 3 tries because of us.
    sender, _ = make_sender(answer)

    with pytest.raises(SmsDeliveryError) as problem:
        sender.check_code(PHONE, CODE)

    assert problem.value.status == answer[0]


# --- no answer -------------------------------------------------------------------------


@pytest.mark.parametrize(
    "failure",
    [
        TimeoutError("timed out"),
        ConnectionResetError("reset"),
        urllib.error.URLError("https://api.authentica.sa could not be reached"),
        http.client.RemoteDisconnected("closed"),
        http.client.IncompleteRead(b"abc"),
    ],
)
def test_no_answer_is_an_error_that_does_not_repeat_the_text_of_the_failure(failure):
    sender, _ = make_sender(failure, failure)

    for action in (
        lambda: sender.send_code(PHONE),
        lambda: sender.check_code(PHONE, CODE),
    ):
        with pytest.raises(SmsDeliveryError) as problem:
            action()
        assert type(failure).__name__ in str(problem.value)
        assert "api.authentica.sa" not in str(problem.value)
        for secret in (KEY, PHONE, CODE):
            assert secret not in str(problem.value)
        assert problem.value.status is None


# --- the key, the phone number and the code stay out of the logs -----------------------


def test_nothing_secret_is_logged(caplog):
    sender, _ = make_sender(SEND_OK, VERIFY_OK, VERIFY_REFUSED, WRONG_KEY, TimeoutError("x"))

    with caplog.at_level("DEBUG"):
        sender.send_code(PHONE)
        sender.check_code(PHONE, CODE)
        sender.check_code(PHONE, CODE)
        with pytest.raises(SmsDeliveryError):
            sender.check_code(PHONE, CODE)
        with pytest.raises(SmsDeliveryError):
            sender.check_code(PHONE, CODE)

    assert "Authentica" in caplog.text  # something was logged
    for secret in (KEY, PHONE, CODE, PHONE[1:]):
        assert secret not in caplog.text


# --- how the sender is built -------------------------------------------------------------


def test_an_empty_key_is_refused():
    with pytest.raises(ConfigError, match="AUTHENTICA_API_KEY"):
        AuthenticaSmsSender("")


def test_the_address_must_be_https_so_the_key_never_travels_in_clear():
    with pytest.raises(ConfigError, match="https"):
        AuthenticaSmsSender(KEY, base_url="http://api.authentica.sa/api/v2")


def test_a_slash_at_the_end_of_the_address_is_harmless():
    sender, transport = make_sender(SEND_OK, base_url="https://example.test/v2/")

    sender.send_code(PHONE)

    assert transport.calls[0]["url"] == "https://example.test/v2/send-otp"


# --- the default HTTP function (the opener is replaced, so there is no network) ------------


class FakeResponse:
    def __init__(self, status, body: bytes):
        self.status = status
        self._body = body

    def read(self):
        return self._body

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


def test_the_default_function_sends_json_with_the_key_in_the_header(monkeypatch):
    seen = {}

    def fake_open(request, timeout=None):
        seen["request"], seen["timeout"] = request, timeout
        return FakeResponse(200, b'{"success": true}')

    monkeypatch.setattr(authentica._opener, "open", fake_open)

    status, body = urllib_post(
        "https://api.authentica.sa/api/v2/send-otp",
        {"X-Authorization": KEY},
        {"phone": PHONE},
        7.5,
    )

    request = seen["request"]
    assert (status, body) == (200, {"success": True})
    assert request.get_method() == "POST"
    assert request.full_url == "https://api.authentica.sa/api/v2/send-otp"
    assert request.get_header("X-authorization") == KEY
    assert request.get_header("Content-type") == "application/json"
    assert json.loads(request.data) == {"phone": PHONE}
    assert seen["timeout"] == 7.5


def test_the_default_function_returns_a_422_answer_instead_of_raising(monkeypatch):
    def fake_open(request, timeout=None):
        raise urllib.error.HTTPError(
            request.full_url,
            422,
            "Unprocessable",
            {},
            io.BytesIO(b'{"status": false, "message": "Failed to verify OTP"}'),
        )

    monkeypatch.setattr(authentica._opener, "open", fake_open)

    status, body = urllib_post("https://x.test/verify-otp", {}, {}, 5)

    assert (status, body["status"]) == (422, False)


def test_the_default_function_copes_with_an_answer_that_is_not_json(monkeypatch):
    def fake_open(request, timeout=None):
        return FakeResponse(200, b"<html>gateway</html>")

    monkeypatch.setattr(authentica._opener, "open", fake_open)

    assert urllib_post("https://x.test/send-otp", {}, {}, 5) == (200, None)


def test_a_redirect_is_never_followed_because_the_key_would_follow_it():
    handler = authentica._NoRedirect()

    assert handler.redirect_request(None, None, 302, "Found", {}, "https://evil.test/") is None
