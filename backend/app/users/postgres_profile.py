"""Saving an account's names, birth date and city in PostgreSQL."""

from datetime import date
from uuid import UUID

from app.database import db, transaction
from app.models import Account
from app.users.account_rows import as_user
from app.users.user import User


class PostgresProfiles:
    """Saves the profile of an account."""

    def update_profile(
        self,
        user_id: str,
        first_name: str,
        last_name: str,
        display_name: str,
        birth_date: date | None = None,
        city: str | None = None,
    ) -> User | None:
        """Replace the complete name group in one transaction.

        A birth date or city that is None keeps the saved one.
        """
        # An id that is not a UUID is no account; the account is locked while
        # its profile changes.
        try:
            account_id = UUID(user_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with transaction():
            account = db.session.get(Account, account_id, with_for_update=True)
            if account is None:
                return None
            account.first_name = first_name
            account.last_name = last_name
            account.display_name = display_name
            # The birth date and city change only when sent (onboarding sends
            # them, the account page does not).
            if birth_date is not None:
                account.birth_date = birth_date
            if city is not None:
                account.city = city
            db.session.flush()
            return as_user(account)
