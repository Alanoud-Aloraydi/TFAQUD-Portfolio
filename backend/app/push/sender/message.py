"""A push message, and what every push sender can do."""

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class PushMessage:
    """What the phone shows: a title and a line. `kind` tells the app what
    it is about (an invitation, a request, an answer)."""

    title: str
    body: str
    kind: str


class PushSender(Protocol):
    """What every push sender has: `enabled`, `send` to one account, and
    `deleted_apps` of one account."""
    enabled: bool

    def send(self, account_id: str, message: PushMessage) -> str:
        """Send to the account's phones; answer SENT, NO_DEVICE or FAILED.
        """

    def deleted_apps(self, account_id: str) -> set[str]:
        """The OneSignal subscription ids of the account's phones whose app
        was deleted; empty when unsure."""
