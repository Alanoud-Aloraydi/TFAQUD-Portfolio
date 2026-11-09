"""The demo accounts sign in with one code and no SMS, on a server that
sends real SMS to everyone else."""

import pytest

from app.clock import SystemClock
from app.config import ConfigError, load_config
from app.demo_accounts import DEMO_PHONES
from app.sms import DemoSmsSender, FakeSmsSender, create_sms_sender

OTHER = "+966511111111"


def _sender():
    real = FakeSmsSender(SystemClock(), log_body=False, valid_seconds=300)
    return real, DemoSmsSender(real, DEMO_PHONES, "246810")


def test_a_demo_number_gets_no_sms_and_signs_in_with_the_demo_code():
    real, sender = _sender()

    sender.send_code(DEMO_PHONES[0])

    assert real.outbox == []
    assert sender.check_code(DEMO_PHONES[0], "246810") is True
    assert sender.check_code(DEMO_PHONES[0], "135790") is False


def test_every_other_number_goes_to_the_real_sender():
    real, sender = _sender()

    sender.send_code(OTHER)

    sent = real.last_message_to(OTHER)
    assert sent is not None
    # The demo code opens nothing but the demo numbers.
    assert sender.check_code(OTHER, "246810") is False
    assert sender.check_code(OTHER, sent.code) is True


def test_the_sender_keeps_the_demo_numbers_only_with_the_code():
    plain = create_sms_sender(load_config("testing"), SystemClock())
    demo = create_sms_sender(
        load_config("testing", {"DEMO_SIGN_IN_CODE": "246810"}),
        SystemClock(),
    )

    assert isinstance(plain, FakeSmsSender)
    assert isinstance(demo, DemoSmsSender)


@pytest.mark.parametrize("code", ["12345", "1234567", "abcdef", "١٢٣٤٥٦"])
def test_a_demo_code_must_be_six_digits(code):
    with pytest.raises(ConfigError, match="six digits"):
        load_config("testing", {"DEMO_SIGN_IN_CODE": code})


def test_production_refuses_a_demo_code(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 64)
    monkeypatch.setenv("DEMO_SIGN_IN_CODE", "246810")

    with pytest.raises(ConfigError, match="production"):
        load_config("production")
