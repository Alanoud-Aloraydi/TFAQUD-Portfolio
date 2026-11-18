"""Saudi mobile numbers as people write them, in the one form the server
keeps them: +9665 and eight more digits."""

import os
import re

from app.config.errors import ConfigError

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
