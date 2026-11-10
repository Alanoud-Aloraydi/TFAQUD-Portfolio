"""Push notifications to the phones of signed-in accounts.

`create_push_sender` picks the sender named by PUSH_BACKEND, `notify` sends a
message to every signed-in phone of some accounts, and `routes` lets the app
register its phone's token.
"""

from pathlib import Path

from app.config import ConfigError
from app.push.sender import (
    ApnsPushSender,
    NoPushSender,
    PushMessage,
    PushSender,
    RecordingPushSender,
)

_APNS_SETTINGS = (
    "APNS_KEY_ID",
    "APNS_TEAM_ID",
    "APNS_BUNDLE_ID",
    "APNS_PRIVATE_KEY_PATH",
)


def create_push_sender(config: dict) -> PushSender:
    """"none" sends nothing; "apns" needs every APNS_* setting and the key."""
    # "none", or "apns" with every setting and a readable key file.
    backend = config.get("PUSH_BACKEND", "none")
    if backend == "none":
        return NoPushSender()
    if backend != "apns":
        raise ConfigError(
            f"Unknown PUSH_BACKEND {backend!r}. Use 'none' or 'apns'."
        )
    missing = [name for name in _APNS_SETTINGS if not config.get(name)]
    if missing:
        raise ConfigError(
            "PUSH_BACKEND is apns, so these are required: "
            + ", ".join(missing)
            + "."
        )
    environment = config.get("APNS_ENVIRONMENT") or "sandbox"
    if environment not in ("sandbox", "production"):
        raise ConfigError(
            "APNS_ENVIRONMENT must be sandbox or production, "
            f"got {environment!r}."
        )
    key_path = Path(config["APNS_PRIVATE_KEY_PATH"])
    try:
        private_key = key_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise ConfigError(
            f"The Apple push key cannot be read at {key_path}."
        ) from exc
    return ApnsPushSender(
        key_id=config["APNS_KEY_ID"],
        team_id=config["APNS_TEAM_ID"],
        bundle_id=config["APNS_BUNDLE_ID"],
        private_key=private_key,
        environment=environment,
    )


__all__ = [
    "ApnsPushSender",
    "NoPushSender",
    "PushMessage",
    "PushSender",
    "RecordingPushSender",
    "create_push_sender",
]
