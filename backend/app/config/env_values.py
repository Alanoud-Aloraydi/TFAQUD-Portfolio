"""Typed values read from environment variables, refused when malformed."""

import os

from app.config.errors import ConfigError


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
