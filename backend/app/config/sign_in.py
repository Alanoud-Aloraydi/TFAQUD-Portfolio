"""The sign-in settings: tokens, sign-in codes, their limits and the SMS
that carries them."""

import os

from app.config.defaults import (
    DEFAULT_ACCESS_TOKEN_MINUTES,
    DEFAULT_AUTHENTICA_TEMPLATE_ID,
    DEFAULT_OTP_MAX_SENDS_PER_DAY,
    DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR,
    DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR,
    DEFAULT_OTP_MAX_WRONG_TRIES,
    DEFAULT_OTP_RESEND_WAITS,
    DEFAULT_OTP_VALID_SECONDS,
)
from app.config.env_values import (
    cap_from_env,
    flag_from_env,
    int_from_env,
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
