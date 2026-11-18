"""Sending and checking sign-in codes: `create_sms_sender` picks the sender
named by SMS_BACKEND (Authentica, or the fake one for tests and local work),
and keeps the demo numbers away from it.
"""

from app.config import ConfigError
from app.demo_accounts import SIGN_IN_DEMO_PHONES
from app.resilience import CircuitBreaker
from app.sms.authentica import AuthenticaSmsSender
from app.sms.authentica_keys import AuthenticaKeys
from app.sms.base import CODE_LENGTH, SmsDeliveryError, SmsSender
from app.sms.demo import DemoSmsSender
from app.sms.fake import FakeSmsSender, SentSms


def create_sms_sender(config: dict, clock) -> SmsSender:
    """The sender named by `SMS_BACKEND`, and with DEMO_SIGN_IN_CODE set,
    the demo numbers and the DEMO_SIGN_IN_PHONES kept away from it
    (DemoSmsSender).
    """
    sender = _create_sender(config, clock)
    code = config.get("DEMO_SIGN_IN_CODE")
    if code is None:
        return sender
    phones = (*SIGN_IN_DEMO_PHONES, *config.get("DEMO_SIGN_IN_PHONES", ()))
    return DemoSmsSender(sender, phones, code)


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
        keys = (api_key, *config.get("AUTHENTICA_BACKUP_API_KEYS", ()))
        senders = [
            AuthenticaSmsSender(
                key, template_id=config["AUTHENTICA_TEMPLATE_ID"],
                breaker=CircuitBreaker(
                    "authentica" if place == 0 else f"authentica-{place + 1}"
                ),
            )
            for place, key in enumerate(keys)
        ]
        if len(senders) == 1:
            return senders[0]
        return AuthenticaKeys(
            senders, low=config["AUTHENTICA_LOW_BALANCE"], clock=clock
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
