"""The settings of sign-in (tokens, codes, their limits and the SMS that
carries them) and of the services around it: pushes, the demo accounts,
the scheduled scan and work done after the answer."""

import os

from app.config.values import (
    DEFAULT_ACCESS_TOKEN_MINUTES,
    DEFAULT_AUTHENTICA_TEMPLATE_ID,
    DEFAULT_OTP_MAX_SENDS_PER_DAY,
    DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR,
    DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR,
    DEFAULT_OTP_MAX_WRONG_TRIES,
    DEFAULT_OTP_RESEND_WAITS,
    DEFAULT_OTP_VALID_SECONDS,
    cap_from_env,
    flag_from_env,
    int_from_env,
    phones_from_env,
    waits_from_env,
)


def sign_in_settings(env_name: str) -> dict:
    """The sign-in part of the settings for `env_name`."""
    testing = env_name == "testing"
    return {
        "ACCESS_TOKEN_MINUTES": int_from_env(
            "ACCESS_TOKEN_MINUTES", DEFAULT_ACCESS_TOKEN_MINUTES
        ),
        "SMS_BACKEND": os.environ.get("SMS_BACKEND", "fake"),
        "OTP_VALID_SECONDS": int_from_env(
            "OTP_VALID_SECONDS", DEFAULT_OTP_VALID_SECONDS
        ),
        "OTP_MAX_WRONG_TRIES": int_from_env(
            "OTP_MAX_WRONG_TRIES", DEFAULT_OTP_MAX_WRONG_TRIES
        ),
        "OTP_MAX_SENDS_PER_DAY": int_from_env(
            "OTP_MAX_SENDS_PER_DAY", DEFAULT_OTP_MAX_SENDS_PER_DAY
        ),
        # The tests send many codes in a row: there, no waits and no device
        # or IP caps unless a test sets them.
        "OTP_RESEND_WAITS": waits_from_env(
            "OTP_RESEND_WAITS", () if testing else DEFAULT_OTP_RESEND_WAITS
        ),
        "OTP_MAX_SENDS_PER_DEVICE_HOUR": cap_from_env(
            "OTP_MAX_SENDS_PER_DEVICE_HOUR",
            None if testing else DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR,
        ),
        "OTP_MAX_SENDS_PER_IP_HOUR": cap_from_env(
            "OTP_MAX_SENDS_PER_IP_HOUR",
            None if testing else DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR,
        ),
        # The header that holds the caller's real address behind a proxy
        # (Render: CF-Connecting-IP). Empty: the connection's address.
        "CLIENT_IP_HEADER": os.environ.get("CLIENT_IP_HEADER", "").strip(),
        # Provider credentials remain server-side.
        "AUTHENTICA_API_KEY": os.environ.get("AUTHENTICA_API_KEY"),
        # Ready keys of other Authentica accounts, comma-separated: codes go
        # out with the next one when an account is under AUTHENTICA_LOW_
        # BALANCE points (app/sms/authentica_keys.py).
        "AUTHENTICA_BACKUP_API_KEYS": tuple(
            key.strip()
            for key in os.environ.get("AUTHENTICA_BACKUP_API_KEYS", "")
            .split(",")
            if key.strip()
        ),
        "AUTHENTICA_LOW_BALANCE": int_from_env("AUTHENTICA_LOW_BALANCE", 20),
        "AUTHENTICA_TEMPLATE_ID": int_from_env(
            "AUTHENTICA_TEMPLATE_ID", DEFAULT_AUTHENTICA_TEMPLATE_ID
        ),
        # Only the fake sender logs its codes: always in development, and in
        # staging when FAKE_SMS_LOG_CODES=true (a shared test server whose log
        # only the team can read, such as Render). Never in production, which
        # refuses the fake sender anyway.
        "FAKE_SMS_LOG_BODY": env_name == "development"
        or (env_name == "staging" and flag_from_env("FAKE_SMS_LOG_CODES")),
    }


def service_settings(env_name: str) -> dict:
    """The push, demo, scan and background part of the settings."""
    return {
        # Push notifications: "none" (nothing is sent) or "onesignal"
        # (iOS and Android, through OneSignal). The app id names the
        # OneSignal app; the App API key is a secret, typed in Render only.
        "PUSH_BACKEND": os.environ.get("PUSH_BACKEND", "none"),
        "ONESIGNAL_APP_ID": os.environ.get("ONESIGNAL_APP_ID"),
        "ONESIGNAL_API_KEY": os.environ.get("ONESIGNAL_API_KEY"),
        # The reminders at a task's time, sent by the server to the phones
        # whose app asks for them (app/push/reminders.py). "false"
        # sends none, and each app sets its own again when it next opens.
        "SERVER_REMINDERS": os.environ.get(
            "SERVER_REMINDERS", "true"
        ).strip().lower() in ("1", "true", "yes"),
        # The one code the demo accounts (app/demo.py) sign in
        # with, six digits, so a shared test server with real SMS can show
        # the demo: those made-up numbers get no SMS. Unset: no demo
        # sign-in. Refused in production.
        "DEMO_SIGN_IN_CODE": (
            os.environ.get("DEMO_SIGN_IN_CODE", "").strip() or None
        ),
        # More numbers that sign in with that code and get no SMS: the
        # team's own phones on the shared test server, comma-separated,
        # typed in Render (Environment), never in git. Anyone who knows one
        # of them and the code can open its account.
        "DEMO_SIGN_IN_PHONES": phones_from_env("DEMO_SIGN_IN_PHONES"),
        # The App Store and Google Play reviewers' sign-in, the one kind
        # allowed in production: these numbers get no SMS and sign in with
        # REVIEW_SIGN_IN_CODE (six digits). Both are typed in Render only,
        # never in git, and both unset means no such sign-in.
        "REVIEW_SIGN_IN_PHONES": phones_from_env("REVIEW_SIGN_IN_PHONES"),
        "REVIEW_SIGN_IN_CODE": (
            os.environ.get("REVIEW_SIGN_IN_CODE", "").strip() or None
        ),
        # Shared secret for /internal/tick and /internal/metrics (the
        # scheduled scan runs as `flask --app wsgi tick` on Render's cron).
        # None (unset) keeps the endpoints refusing every request.
        "TICK_SECRET": os.environ.get("TICK_SECRET"),
        # The API's health check, asked by each scheduled scan so the free
        # API never sleeps (app/background.py). Unset: nothing is asked.
        "KEEP_AWAKE_URL": os.environ.get("KEEP_AWAKE_URL") or None,
        # The same scan inside each API process, every this many seconds
        # (app/background.py), so a missed task is told within a minute;
        # 0 turns it off. On by default on Render (staging, production).
        "SCAN_EVERY_SECONDS": int(
            os.environ.get("SCAN_EVERY_SECONDS")
            or (60 if env_name in ("staging", "production") else 0)
        ),
        # Push notifications and other work no one waits for run after the
        # answer (app/background.py); tests run them at once.
        "BACKGROUND_INLINE": env_name == "testing",
    }
