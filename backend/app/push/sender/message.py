"""A push message, and what every push sender can do."""

from collections.abc import Collection
from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class PushMessage:
    """What the phone shows: a title and a line. `kind` tells the app what
    it is about (an invitation, a request, an answer), and `target` which
    item, as pairs of text (app/push/targets.py), so a tap opens it.

    `thread` stacks pushes together on the phone (the kind when None), and
    `category` is the iOS category whose buttons the push shows («ذكّرني
    لاحقًا» on a reminder), registered by the app."""

    title: str
    body: str
    kind: str
    target: tuple[tuple[str, str], ...] = ()
    thread: str | None = None
    category: str | None = None


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
