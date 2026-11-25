"""The values the settings are made of: the environments and their
defaults, typed values read from environment variables, Saudi mobile
numbers, and the error that keeps the server from starting with bad
settings."""

import os
import re


class ConfigError(RuntimeError):
    """The settings are missing or unsafe. The app must not start."""


ENVIRONMENTS = ("development", "testing", "staging", "production")

# Default access-token lifetime, overridable through an environment variable.
# A refresh token has none: it works until its session is signed out.
DEFAULT_ACCESS_TOKEN_MINUTES = 15

# OTP validity matches the provider's configured lifetime.
DEFAULT_OTP_VALID_SECONDS = 300

DEFAULT_AUTHENTICA_TEMPLATE_ID = 5  # Arabic text, code of 6 digits

# Server-side limits are configurable per environment.
DEFAULT_OTP_MAX_WRONG_TRIES = 3  # per verification request

# Codes to one phone number in 24 hours, counted since its last sign-in.
DEFAULT_OTP_MAX_SENDS_PER_DAY = 20

# Seconds to wait after the 1st, 2nd, 3rd ... code before the next one; the
# last one repeats. Someone who types another person's number can then only
# slow the owner (at most 10 minutes), never lock them out.
DEFAULT_OTP_RESEND_WAITS = (30, 60, 120, 300, 600)

# Codes one device (X-Device-Id) and one IP may ask for in an hour, for any
# numbers, so one phone or one network cannot send codes to many people.
DEFAULT_OTP_MAX_SENDS_PER_DEVICE_HOUR = 10

DEFAULT_OTP_MAX_SENDS_PER_IP_HOUR = 30

# Every database call has a deadline, like every call to another service:
# a hung query or a held lock must not hold a request (and a gunicorn
# worker) until gunicorn kills it after 120 seconds.
DEFAULT_DATABASE_STATEMENT_TIMEOUT_MS = 5_000

DEFAULT_DATABASE_LOCK_TIMEOUT_MS = 3_000

# A transaction left open and idle (a bug) is ended after this.
DEFAULT_DATABASE_IDLE_IN_TRANSACTION_MS = 30_000

DEFAULT_DATABASE_CONNECT_TIMEOUT_SECONDS = 5

# Waiting for a free connection of the pool.
DEFAULT_DATABASE_POOL_TIMEOUT_SECONDS = 5

MIN_SECRET_KEY_LENGTH = 32

DEV_SECRET_KEY = "development-only-secret-key-not-for-real-use"

TEST_SECRET_KEY = "testing-only-secret-key-not-for-real-use!!"


def waits_from_env(name: str, default: tuple[int, ...]) -> tuple[int, ...]:
    """Whole seconds separated by commas, such as "30,60,120"; "0": none."""
    raw = os.environ.get(name)
    if raw is None or raw.strip() == "":
        return default
    if raw.strip() == "0":
        return ()
    try:
        waits = tuple(int(part) for part in raw.split(","))
    except ValueError as exc:
        raise ConfigError(
            f"{name} must be whole seconds separated by commas, got {raw!r}."
        ) from exc
    if any(wait <= 0 for wait in waits):
        raise ConfigError(f"{name} must hold numbers greater than zero.")
    return waits


def cap_from_env(name: str, default: int | None) -> int | None:
    """A whole number greater than zero, or "0" for no cap."""
    raw = os.environ.get(name)
    if raw is not None and raw.strip() == "0":
        return None
    if raw is None or raw == "":
        return default
    return int_from_env(name, 1)


def int_from_env(name: str, default: int) -> int:
    """A whole number above zero from the environment variable `name`, or
    `default` when it is not set or empty.
    """
    raw = os.environ.get(name)
    if raw is None or raw == "":
        return default
    try:
        value = int(raw)
    except ValueError as exc:
        raise ConfigError(
            f"{name} must be a whole number, got {raw!r}."
        ) from exc
    if value <= 0:
        raise ConfigError(f"{name} must be greater than zero, got {value}.")
    return value


def flag_from_env(name: str) -> bool:
    """Whether the environment variable `name` says yes."""
    value = os.environ.get(name, "").strip().lower()
    return value in ("1", "true", "yes")


_SEPARATORS = re.compile(r"[\s-]")


def saudi_mobile(text: str) -> str | None:
    """`text` as +9665XXXXXXXX, or None when it is not a Saudi mobile
    number. Takes 5XXXXXXXX, 05XXXXXXXX, 9665XXXXXXXX and +9665XXXXXXXX,
    with spaces or dashes between the digits."""
    digits = _SEPARATORS.sub("", text.strip())
    if digits.startswith("+"):
        if not digits.startswith("+966"):
            return None
        digits = digits[1:]
    if digits.startswith("966"):
        digits = digits[3:]
    elif digits.startswith("0"):
        digits = digits[1:]
    if (
        len(digits) == 9
        and digits.isascii()
        and digits.isdigit()
        and digits.startswith("5")
    ):
        return f"+966{digits}"
    return None


def phones_from_env(name: str) -> tuple[str, ...]:
    """Saudi mobile numbers separated by commas, each as +9665XXXXXXXX;
    unset or empty: none. A value that is not such a number stops the
    start; the error does not repeat it, since it may be a person's."""
    phones: list[str] = []
    for part in os.environ.get(name, "").split(","):
        if not part.strip():
            continue
        phone = saudi_mobile(part)
        if phone is None:
            raise ConfigError(
                f"{name} must hold Saudi mobile numbers separated by "
                "commas, such as 5XXXXXXXX."
            )
        phones.append(phone)
    # Each number once, in the order given.
    return tuple(dict.fromkeys(phones))
