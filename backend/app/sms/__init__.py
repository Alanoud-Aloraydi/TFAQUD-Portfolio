"""Sending and checking sign-in codes: `create_sms_sender` picks the sender
named by SMS_BACKEND (Authentica, or the fake one for tests and local work),
and keeps the demo numbers away from it.
"""

from app.config import ConfigError
from app.demo_accounts import DEMO_PHONES
from app.sms.authentica import AuthenticaSmsSender
from app.sms.base import CODE_LENGTH, SmsDeliveryError, SmsSender
from app.sms.demo import DemoSmsSender
from app.sms.fake import FakeSmsSender, SentSms


def create_sms_sender(config: dict, clock) -> SmsSender:
    """The sender named by `SMS_BACKEND`, and with DEMO_SIGN_IN_CODE set,
    the demo accounts' numbers kept away from it (DemoSmsSender).
    """
    sender = _create_sender(config, clock)
    code = config.get("DEMO_SIGN_IN_CODE")
    if code is None:
        return sender
    return DemoSmsSender(sender, DEMO_PHONES, code)


def _create_sender(config: dict, clock) -> SmsSender:
    """Pick the sender named by `SMS_BACKEND`: "fake" or "authentica".

    Two rules protect against sending by mistake:
      - the testing environment can only ever use the fake sender;
      - the production environment can never use the fake sender.
    Choosing "authentica" needs AUTHENTICA_API_KEY. Creating the sender makes
    no call: the first call happens when a code is sent or checked.
    """
    backend = config["SMS_BACKEND"]
    env = config["APP_ENV"]

    # The fake sender, anywhere but production.
    if backend == "fake":
        if env == "production":
            raise ConfigError(
                "The fake SMS sender cannot be used in production."
            )
        return FakeSmsSender(
            clock,
            log_body=config["FAKE_SMS_LOG_BODY"],
            valid_seconds=config["OTP_VALID_SECONDS"],
        )

    # The real one needs its key, and tests never get it.
    if env == "testing":
        raise ConfigError("Tests may only use the fake SMS sender.")
    if backend == "authentica":
        api_key = config.get("AUTHENTICA_API_KEY")
        if not api_key:
            raise ConfigError(
                "SMS_BACKEND is authentica, so AUTHENTICA_API_KEY is required."
            )
        return AuthenticaSmsSender(
            api_key, template_id=config["AUTHENTICA_TEMPLATE_ID"]
        )
    raise ConfigError(
        f"Unknown SMS_BACKEND {backend!r}. Use 'fake' or 'authentica'."
    )


__all__ = [
    "AuthenticaSmsSender",
    "CODE_LENGTH",
    "DemoSmsSender",
    "FakeSmsSender",
    "SentSms",
    "SmsDeliveryError",
    "SmsSender",
    "create_sms_sender",
]
