"""Senders of push notifications, through OneSignal (iOS and Android).

OneSignal knows each phone by the account signed in on it: the app calls
OneSignal's `login` with the account's id (its "external id") and `logout`
at sign-out. So the server sends to an account, never to a phone token.
Without PUSH_BACKEND=onesignal and its two settings (README.md), the server
uses `NoPushSender`, which sends nothing.

A sender also says which of an account's phones deleted the app
(`deleted_apps`), so their sign-ins can end (notify.py)."""

from app.push.sender.fakes import NoPushSender, RecordingPushSender
from app.push.sender.message import PushMessage, PushSender
from app.push.sender.onesignal import OneSignalPushSender
from app.push.sender.onesignal_api import (
    APP_DELETED,
    NOTIFICATION_SOUND,
    ONESIGNAL_URL,
    ONESIGNAL_USER_URL,
)
from app.push.sender.outcomes import FAILED, NO_DEVICE, SENT

__all__ = [
    "APP_DELETED",
    "FAILED",
    "NOTIFICATION_SOUND",
    "NO_DEVICE",
    "NoPushSender",
    "ONESIGNAL_URL",
    "ONESIGNAL_USER_URL",
    "OneSignalPushSender",
    "PushMessage",
    "PushSender",
    "RecordingPushSender",
    "SENT",
]
