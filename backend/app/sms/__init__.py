from app.config import ConfigError
from app.sms.base import SmsDeliveryError, SmsSender
from app.sms.fake import FakeSmsSender, SentSms


def create_sms_sender(config: dict, clock) -> SmsSender:
    """Pick the SMS sender named by `SMS_BACKEND`.

    Only "fake" exists today. Two rules protect against sending by mistake:
      - the testing environment can only ever use the fake sender;
      - the production environment can never use the fake sender.
    """
    backend = config["SMS_BACKEND"]
    env = config["APP_ENV"]

    if backend == "fake":
        if env == "production":
            raise ConfigError("The fake SMS sender cannot be used in production.")
        return FakeSmsSender(clock, log_body=config["FAKE_SMS_LOG_BODY"])

    if env == "testing":
        raise ConfigError("Tests may only use the fake SMS sender.")
    if backend == "authentica":
        raise ConfigError(
            "The Authentica sender is not built yet. It is added with TFQD-12 and F01."
        )
    raise ConfigError(f"Unknown SMS_BACKEND {backend!r}. Use 'fake'.")


__all__ = [
    "FakeSmsSender",
    "SentSms",
    "SmsDeliveryError",
    "SmsSender",
    "create_sms_sender",
]
