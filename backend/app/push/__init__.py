"""Push notifications to the phones of signed-in accounts, through OneSignal.

`create_push_sender` picks the sender named by PUSH_BACKEND, and `notify`
sends a message to the phones of some accounts. The app ties each phone to
its account in OneSignal (its external id), so the server keeps no phone
tokens.
"""

from app.config.values import ConfigError
from app.push.onesignal import OneSignalPushSender
from app.push.sender import (
    NoPushSender,
    PushMessage,
    PushSender,
    RecordingPushSender,
)

_ONESIGNAL_SETTINGS = ("ONESIGNAL_APP_ID", "ONESIGNAL_API_KEY")


def create_push_sender(config: dict) -> PushSender:
    """"none" sends nothing; "onesignal" needs both ONESIGNAL_* settings."""
    backend = config.get("PUSH_BACKEND", "none")
    if backend == "none":
        return NoPushSender()
    if backend == "apns":
        raise ConfigError(
            "PUSH_BACKEND apns was replaced by OneSignal: set PUSH_BACKEND to "
            "onesignal, with ONESIGNAL_APP_ID and ONESIGNAL_API_KEY."
        )
    if backend != "onesignal":
        raise ConfigError(
            f"Unknown PUSH_BACKEND {backend!r}. Use 'none' or 'onesignal'."
        )
    missing = [name for name in _ONESIGNAL_SETTINGS if not config.get(name)]
    if missing:
        raise ConfigError(
            "PUSH_BACKEND is onesignal, so these are required: "
            + ", ".join(missing)
            + "."
        )
    return OneSignalPushSender(
        app_id=config["ONESIGNAL_APP_ID"],
        api_key=config["ONESIGNAL_API_KEY"],
    )


__all__ = [
    "NoPushSender",
    "OneSignalPushSender",
    "PushMessage",
    "PushSender",
    "RecordingPushSender",
    "create_push_sender",
]
