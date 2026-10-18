"""The SMS sender: tests use the fake one and send nothing real."""

import socket

import pytest

from app import create_app
from app.config import ConfigError
from app.sms import FakeSmsSender, SmsSender


def test_the_app_under_test_uses_the_fake_sender(sms):
    assert isinstance(sms, FakeSmsSender)
    assert isinstance(sms, SmsSender)


def test_fake_sender_keeps_what_would_have_been_sent(sms, clock):
    sms.send("+966500000001", "Your code is 1234")

    assert len(sms.outbox) == 1
    sent = sms.outbox[0]
    assert (sent.to, sent.message, sent.sent_at) == (
        "+966500000001",
        "Your code is 1234",
        clock.now(),
    )


def test_last_message_to_finds_the_latest_for_that_number(sms):
    sms.send("+966500000001", "first")
    sms.send("+966500000002", "other person")
    sms.send("+966500000001", "second")

    assert sms.last_message_to("+966500000001").message == "second"
    assert sms.last_message_to("+966500000009") is None


def test_fake_sender_does_not_log_the_message_body_in_tests(sms, caplog):
    with caplog.at_level("INFO"):
        sms.send("+966500000001", "Your code is 9876")

    assert "9876" not in caplog.text


def test_in_development_the_fake_sender_logs_the_message_so_the_developer_can_read_the_otp(
    caplog,
):
    app = create_app("development")

    with caplog.at_level("INFO"):
        app.extensions["sms_sender"].send("+966500000001", "Your code is 9876")

    assert "9876" in caplog.text
    assert "not sent" in caplog.text


def test_tests_cannot_open_a_network_connection():
    with pytest.raises(AssertionError, match="network connection"):
        socket.create_connection(("example.com", 80))


def test_testing_environment_refuses_any_sender_but_the_fake_one():
    with pytest.raises(ConfigError, match="only use the fake"):
        create_app("testing", overrides={"SMS_BACKEND": "authentica"})


def test_testing_environment_ignores_the_sms_backend_environment_variable(monkeypatch):
    monkeypatch.setenv("SMS_BACKEND", "authentica")

    app = create_app("testing")

    assert isinstance(app.extensions["sms_sender"], FakeSmsSender)


def test_production_refuses_the_fake_sender(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 40)

    with pytest.raises(ConfigError, match="cannot be used in production"):
        create_app("production")


def test_unknown_backend_is_refused():
    with pytest.raises(ConfigError, match="Unknown SMS_BACKEND"):
        create_app("development", overrides={"SMS_BACKEND": "carrier-pigeon"})


def test_authentica_backend_is_not_built_yet():
    with pytest.raises(ConfigError, match="not built yet"):
        create_app("development", overrides={"SMS_BACKEND": "authentica"})
