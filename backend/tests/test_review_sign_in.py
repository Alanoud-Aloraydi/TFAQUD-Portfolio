"""The App Store and Google Play reviewers sign in with a fixed code on a
number set in Render, in production too; nobody else does."""

import pytest

from app.clock import SystemClock
from app.config import load_config
from app.config.values import ConfigError
from app.sms import create_sms_sender

REVIEWER = "+966512345678"
OTHER = "+966511111111"


def test_the_reviewer_number_takes_its_code_and_gets_no_sms():
    sender = create_sms_sender(
        load_config(
            "testing",
            {
                "REVIEW_SIGN_IN_PHONES": (REVIEWER,),
                "REVIEW_SIGN_IN_CODE": "135790",
            },
        ),
        SystemClock(),
    )
    real = sender._sender

    sender.send_code(REVIEWER)
    assert real.last_message_to(REVIEWER) is None
    assert sender.check_code(REVIEWER, "135790") is True
    assert sender.check_code(REVIEWER, "000000") is False

    # Everyone else gets a real code, and the review code opens nothing.
    sender.send_code(OTHER)
    assert real.last_message_to(OTHER) is not None
    assert sender.check_code(OTHER, "135790") is False


def test_production_allows_the_review_sign_in(monkeypatch):
    monkeypatch.setenv("SECRET_KEY", "x" * 64)
    monkeypatch.setenv("REVIEW_SIGN_IN_PHONES", "512345678")
    monkeypatch.setenv("REVIEW_SIGN_IN_CODE", "135790")

    config = load_config("production")

    assert config["REVIEW_SIGN_IN_PHONES"] == (REVIEWER,)


@pytest.mark.parametrize(
    "settings",
    [
        {"REVIEW_SIGN_IN_PHONES": (REVIEWER,)},
        {"REVIEW_SIGN_IN_CODE": "135790"},
        {"REVIEW_SIGN_IN_PHONES": (REVIEWER,), "REVIEW_SIGN_IN_CODE": "1357"},
    ],
)
def test_a_half_or_a_bad_review_setting_stops_the_start(settings):
    with pytest.raises(ConfigError, match="REVIEW_SIGN_IN"):
        load_config("testing", settings)
