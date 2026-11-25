"""The team's own phones and the story's request number sign in with the
demo code too, and get no SMS. The team's phones come from Render
(DEMO_SIGN_IN_PHONES), never from the code."""

import pytest

from app.clock import SystemClock
from app.config import load_config
from app.config.values import ConfigError
from app.config.values import phones_from_env, saudi_mobile
from app.demo import REQUEST_DEMO_PHONE
from app.sms import create_sms_sender

TEAM = "+966512345678"
OTHER = "+966511111111"


@pytest.mark.parametrize(
    "written",
    [
        "512345678",
        "0512345678",
        "966512345678",
        "+966512345678",
        " 051 234 5678 ",
        "+966-51-234-5678",
    ],
)
def test_a_saudi_mobile_number_is_read_as_people_write_it(written):
    assert saudi_mobile(written) == TEAM


@pytest.mark.parametrize(
    "written",
    [
        "",
        "12345678",
        "412345678",
        "05123456789",
        "+971512345678",
        "+0512345678",
        "٥١٢٣٤٥٦٧٨",
    ],
)
def test_anything_else_is_not_one(written):
    assert saudi_mobile(written) is None


def test_the_numbers_come_once_each_in_their_order(monkeypatch):
    monkeypatch.setenv("SOME_PHONES", " 512345678, 0512345678 ,,511111111")

    assert phones_from_env("SOME_PHONES") == (TEAM, OTHER)


def test_none_set_means_none(monkeypatch):
    monkeypatch.delenv("SOME_PHONES", raising=False)

    assert phones_from_env("SOME_PHONES") == ()


def test_a_wrong_number_stops_the_start_without_repeating_it(monkeypatch):
    monkeypatch.setenv("SOME_PHONES", "512345678,98765")

    with pytest.raises(ConfigError) as refused:
        phones_from_env("SOME_PHONES")

    assert "98765" not in str(refused.value)


def test_the_team_and_the_request_number_take_the_demo_code():
    sender = create_sms_sender(
        load_config(
            "testing",
            {"DEMO_SIGN_IN_CODE": "246810", "DEMO_SIGN_IN_PHONES": (TEAM,)},
        ),
        SystemClock(),
    )
    real = sender._sender

    for phone in (TEAM, REQUEST_DEMO_PHONE):
        sender.send_code(phone)
        assert real.last_message_to(phone) is None
        assert sender.check_code(phone, "246810") is True

    # Everyone else gets a real code, and the demo code opens nothing.
    sender.send_code(OTHER)
    assert real.last_message_to(OTHER) is not None
    assert sender.check_code(OTHER, "246810") is False


def test_without_the_code_the_team_numbers_get_a_real_sms():
    sender = create_sms_sender(
        load_config("testing", {"DEMO_SIGN_IN_PHONES": (TEAM,)}),
        SystemClock(),
    )

    sender.send_code(TEAM)

    assert sender.last_message_to(TEAM) is not None
