"""The youngest an account holder may be: 15. A patient without an account
(a child cared for by the family) may be any age."""

from datetime import date

from app.errors import ValidationFailed

YOUNGEST_AGE = 15


def years_before(today: date, years: int) -> date:
    """The same day `years` years back; 28 February for 29 February."""
    try:
        return today.replace(year=today.year - years)
    except ValueError:
        return today.replace(year=today.year - years, day=28)


def require_old_enough(birth_date: date, today: date) -> None:
    """Refuse (`too_young`) a person with an account who is not yet 15 on
    `today`."""
    if birth_date > years_before(today, YOUNGEST_AGE):
        raise ValidationFailed(
            f"An account holder must be at least {YOUNGEST_AGE} years old.",
            code="too_young",
        )
