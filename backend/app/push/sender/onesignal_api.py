"""OneSignal's addresses, its code for a deleted app, and the sound
every push plays."""


ONESIGNAL_URL = "https://api.onesignal.com/notifications?c=push"


# One account, by its external id, with its phones ("subscriptions").
ONESIGNAL_USER_URL = (
    "https://api.onesignal.com/apps/{app_id}/users/by/external_id/{account}"
)


def external_id(account_id: str) -> str:
    """The account as the app names it to OneSignal (OneSignal.login): the
    id the API answers, without dashes (app/users/account_rows.py).
    OneSignal matches an external id letter for letter, so the dashed form
    of the same id reaches no phone and finds no user."""
    return account_id.replace("-", "")


# OneSignal's `notification_types` for a phone whose app was deleted: set by
# OneSignal itself when Apple or Google refuses the phone's token. A phone
# that only turned notifications off is 0 (its app still says so when it
# opens), so it never matches.
APP_DELETED = -10


# The app's notification sound (app/assets/sounds/), the same name the app
# gives its own reminders, so both sound the same.
NOTIFICATION_SOUND = "tafaqod_chime.wav"
