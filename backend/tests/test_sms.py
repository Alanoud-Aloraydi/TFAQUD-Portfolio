"""The sign-in code sender: tests use the fake one and send nothing real."""

import re
import socket

import pytest

from app import create_app
from app.clock import ManualClock
from app.config import ConfigError, load_config
from app.sms import AuthenticaSmsSender, FakeSmsSender, SmsSender, create_sms_sender

PHONE = "+966500000001"


def test_the_app_under_test_uses_the_fake_sender(sms):
    assert isinstance(sms, FakeSmsSender)
    assert isinstance(sms, SmsSender)


# --- sending ------------------------------------------------------------------


def test_fake_sender_keeps_what_would_have_been_sent(sms, clock):
    sms.send_code(PHONE)

    assert len(sms.outbox) == 1
    sent = sms.outbox[0]
    assert (sent.to, sent.sent_at) == (PHONE, clock.now())
    assert re.fullmatch(r"\d{6}", sent.code)
    assert sent.code in sent.message


def test_the_code_has_6_digits_and_keeps_its_leading_zeros(sms, monkeypatch):
    monkeypatch.setattr("app.sms.fake.secrets.randbelow", lambda limit: 42)

    sms.send_code(PHONE)

    assert sms.last_message_to(PHONE).code == "000042"


def test_codes_are_not_always_the_same(sms):
    for _ in range(20):
        sms.send_code(PHONE)

    assert len({sent.code for sent in sms.outbox}) > 1


def test_last_message_to_finds_the_latest_for_that_number(sms):
    sms.send_code("+966500000001")
    sms.send_code("+966500000002")
    sms.send_code("+966500000001")

    assert sms.last_message_to("+966500000001") is sms.outbox[2]
    assert sms.last_message_to("+966500000009") is None


def test_fake_sender_does_not_log_the_code_in_tests(sms, caplog):
    with caplog.at_level("INFO"):
        sms.send_code(PHONE)
        sms.check_code(PHONE, sms.last_message_to(PHONE).code)

    assert sms.last_message_to(PHONE).code not in caplog.text


def test_in_development_the_fake_sender_logs_the_message_so_the_developer_can_read_the_code(
    caplog,
):
    app = create_app("development")
    sender = app.extensions["sms_sender"]

    with caplog.at_level("INFO"):
        sender.send_code(PHONE)

    assert sender.last_message_to(PHONE).code in caplog.text
    assert "not sent" in caplog.text


# --- checking: the rules that Authentica showed ---------------------------------


def test_the_correct_code_is_accepted(sms):
    sms.send_code(PHONE)

    assert sms.check_code(PHONE, sms.last_message_to(PHONE).code) is True


def test_a_code_works_once(sms):
    sms.send_code(PHONE)
    code = sms.last_message_to(PHONE).code

    assert sms.check_code(PHONE, code) is True
    assert sms.check_code(PHONE, code) is False


def test_a_wrong_code_is_refused(sms):
    sms.send_code(PHONE)
    code = sms.last_message_to(PHONE).code
    wrong = "000000" if code != "000000" else "111111"

    assert sms.check_code(PHONE, wrong) is False


@pytest.mark.parametrize("bad", ["", "123", "1234567", "12345a", "١٢٣٤٥٦"])
def test_a_code_of_the_wrong_length_or_kind_is_refused_like_a_wrong_code(sms, bad):
    sms.send_code(PHONE)

    assert sms.check_code(PHONE, bad) is False


def test_the_fake_never_blocks_wrong_tries_like_authentica(sms):
    # Authentica did not block 7 wrong tries and then accepted the correct code.
    # So the limit of 3 wrong tries is the job of our server.
    sms.send_code(PHONE)
    code = sms.last_message_to(PHONE).code
    wrong = "000000" if code != "000000" else "111111"

    assert [sms.check_code(PHONE, wrong) for _ in range(7)] == [False] * 7
    assert sms.check_code(PHONE, code) is True


def test_a_code_is_valid_for_300_seconds(sms, clock):
    sms.send_code(PHONE)
    code = sms.last_message_to(PHONE).code

    clock.advance(seconds=299)
    assert sms.check_code(PHONE, code) is True


def test_a_code_is_refused_after_300_seconds(sms, clock):
    sms.send_code(PHONE)
    code = sms.last_message_to(PHONE).code

    clock.advance(seconds=301)
    assert sms.check_code(PHONE, code) is False


def test_the_validity_comes_from_the_setting():
    clock = ManualClock()
    app = create_app("testing", overrides={"OTP_VALID_SECONDS": 60}, clock=clock)
    sender = app.extensions["sms_sender"]
    sender.send_code(PHONE)
    code = sender.last_message_to(PHONE).code

    clock.advance(seconds=61)

    assert sender.check_code(PHONE, code) is False


def test_a_code_of_another_phone_number_is_refused(sms):
    sms.send_code("+966500000001")
    sms.send_code("+966500000002")
    code_of_first = sms.last_message_to("+966500000001").code

    assert sms.check_code("+966500000002", code_of_first) is False
    assert sms.check_code("+966500000001", code_of_first) is True


def test_a_number_that_got_no_code_has_nothing_to_check(sms):
    assert sms.check_code("+966500000009", "123456") is False


def test_a_new_code_replaces_the_old_code_of_the_same_number(sms, monkeypatch):
    # A choice of the fake. Whether Authentica does the same is test 9 of the guide.
    numbers = iter([111111, 222222])
    monkeypatch.setattr("app.sms.fake.secrets.randbelow", lambda limit: next(numbers))
    sms.send_code(PHONE)
    sms.send_code(PHONE)

    assert sms.check_code(PHONE, "111111") is False
    assert sms.check_code(PHONE, "222222") is True


# --- the rules that stop a real SMS by mistake ------------------------------------


def test_tests_cannot_open_a_network_connection():
    with pytest.raises(AssertionError, match="network connection"):
        socket.create_connection(("example.com", 80))


def test_testing_environment_refuses_any_sender_but_the_fake_one():
    with pytest.raises(ConfigError, match="only use the fake"):
        create_app("testing", overrides={"SMS_BACKEND": "authentica"})


def test_testing_environment_ignores_the_sms_backend_environment_variable(monkeypatch):
    monkeypatch.setenv("SMS_BACKEND", "authentica")
    monkeypatch.setenv("AUTHENTICA_API_KEY", "a-real-looking-key-0123456789")

    app = create_app("testing")

    assert isinstance(app.extensions["sms_sender"], FakeSmsSender)
    assert app.config["AUTHENTICA_API_KEY"] is None


def test_production_refuses_the_fake_sender(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)

    with pytest.raises(ConfigError, match="cannot be used in production"):
        create_app("production")


def test_unknown_backend_is_refused():
    with pytest.raises(ConfigError, match="Unknown SMS_BACKEND"):
        create_app("development", overrides={"SMS_BACKEND": "carrier-pigeon"})


def test_authentica_backend_needs_the_api_key(monkeypatch):
    monkeypatch.delenv("AUTHENTICA_API_KEY", raising=False)

    with pytest.raises(ConfigError, match="AUTHENTICA_API_KEY"):
        create_app("development", overrides={"SMS_BACKEND": "authentica"})


def test_an_empty_api_key_is_refused_like_a_missing_one(monkeypatch):
    monkeypatch.setenv("AUTHENTICA_API_KEY", "")

    with pytest.raises(ConfigError, match="AUTHENTICA_API_KEY"):
        create_app("development", overrides={"SMS_BACKEND": "authentica"})


def test_authentica_backend_with_a_key_builds_the_real_sender_without_any_call():
    # No network is allowed in tests, so this also proves that creating the sender
    # makes no call.
    app = create_app(
        "development",
        overrides={"SMS_BACKEND": "authentica", "AUTHENTICA_API_KEY": "k" * 30},
    )

    assert isinstance(app.extensions["sms_sender"], AuthenticaSmsSender)


def test_production_may_use_authentica():
    config = load_config(
        "production",
        overrides={
            "SECRET_KEY": "x" * 40,
            "SMS_BACKEND": "authentica",
            "AUTHENTICA_API_KEY": "k" * 30,
        },
    )

    sender = create_sms_sender(config, ManualClock())

    assert isinstance(sender, AuthenticaSmsSender)
