"""An account row as the `User` the rest of the server reads."""

from app.models import Account
from app.users.user import User


def as_user(account: Account) -> User:
    """Keep API fields and compact IDs outside persistence."""
    return User(
        id=account.id.hex,
        phone=account.phone_number,
        created_at=account.created_at,
        first_name=account.first_name,
        last_name=account.last_name,
        display_name=account.display_name,
        app_mode=account.app_mode,
        birth_date=account.birth_date,
        city=account.city,
    )
