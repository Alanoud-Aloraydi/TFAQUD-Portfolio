"""A push message, and what every push sender can do."""

from collections.abc import Collection
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class PushMessage:
    """What the phone shows: a title and a line. `kind` tells the app what
    it is about (an invitation, a request, an answer), and `target` which
    item, as pairs of text (app/push/targets.py), so a tap opens it."""

    title: str
    body: str
    kind: str
    target: tuple[tuple[str, str], ...] = ()


class PushSender(Protocol):
    """What every push sender has: `enabled`, `send` to one account, and
    `deleted_apps` of one account."""
    enabled: bool

    def send(
        self,
        account_id: str,
        message: PushMessage,
        phones: Collection[str] = (),
    ) -> str:
        """Send to the account's phones: `phones` (their OneSignal
        subscriptions) when known, else every phone OneSignal ties to the
        account. Answer SENT, NO_DEVICE or FAILED."""

    def deleted_apps(self, account_id: str) -> set[str]:
        """The OneSignal subscription ids of the account's phones whose app
        was deleted; empty when unsure."""
