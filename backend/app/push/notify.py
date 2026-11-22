"""Send one message to the phones of some accounts, through OneSignal.

Called after the request's transaction has committed, so a push never
announces something that was rolled back, and a push that fails never fails
the request. The sending itself runs after the answer (app/background.py):
no one waits for OneSignal.

Only an account that is signed in somewhere gets it. The app unties its
phone from the account at sign-out (OneSignal `logout`); an account whose
every sign-in ended here (expired, signed out elsewhere) is skipped too,
since its phones may not have heard.

A deleted app signs itself out here. A phone tells no one when its app is
deleted, but Apple or Google then refuse its token, and OneSignal marks
that phone's subscription (sender.APP_DELETED). Each sign-in keeps its
phone's subscription (routes.py); after sending, the server asks OneSignal
about the phones of the accounts it sent to, and ends the sign-ins whose
phone deleted the app, as a sign-out would. OneSignal learns of it only
from sends (two or three after the deletion), and Apple can take days."""

import logging
from dataclasses import dataclass
from uuid import UUID

from app import metrics
from app.background import run_later
from app.extensions import get_push_sender
from app.push.delivery import send_to_accounts
from app.push.sender import PushMessage

log = logging.getLogger(__name__)


@dataclass(frozen=True)
class Push:
    """A message and the accounts it goes to. A `reminder` (at a task's
    time) goes only to the phones whose app leaves its reminders to the
    server (app/push/scheduled/reminders): the others set their own."""

    account_ids: tuple[UUID, ...]
    message: PushMessage
    reminder: bool = False


def notify(push: Push | None) -> None:
    """Send `push` to the phones of its accounts that are signed in now.
    Nothing here raises."""
    sender = get_push_sender()
    if push is None or not sender.enabled:
        return
    accounts: set[UUID] = set(push.account_ids)
    if not accounts:
        return
    run_later(_deliver, accounts, push.message, push.reminder)


def _deliver(
    accounts: set[UUID], message: PushMessage, reminder: bool = False
) -> None:
    """The background job: send `message` to the signed-in accounts among
    `accounts`, and never raise.
    """
    try:
        send_to_accounts(
            get_push_sender(), accounts, message, reminder=reminder
        )
    except Exception:  # noqa: BLE001 - see the module docstring
        metrics.increment("push.failed")
        log.warning("Push notifications were not sent.", exc_info=True)
