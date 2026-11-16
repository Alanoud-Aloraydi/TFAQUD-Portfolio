"""PostgreSQL adapter preserving the existing user-facing API contract."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert

from app.database import db, transaction
from app.errors import ServiceUnavailable
from app.models import Account
from app.users.account_rows import as_user
from app.users.postgres_profile import PostgresProfiles
from app.users.store import UserStore
from app.users.user import User

_CREATION_ATTEMPTS = 3


class PostgresUserStore(PostgresProfiles, UserStore):
    """Own one short transaction per existing account-store operation."""

    def get_or_create_by_phone(
        self, phone: str, now: datetime
    ) -> tuple[User, bool]:
        """Use database uniqueness, including concurrent first sign-ins."""
        # Insert the account, or find it when the number has one; another
        # sign-in can make it in between, so a few tries.
        with transaction():
            for _ in range(_CREATION_ATTEMPTS):
                account = db.session.scalar(
                    insert(Account)
                    .values(phone_number=phone, created_at=now)
                    .on_conflict_do_nothing(index_elements=["phone_number"])
                    .returning(Account)
                )
                if account is not None:
                    return as_user(account), True
                account = db.session.scalar(
                    select(Account)
                    .where(Account.phone_number == phone)
                    .with_for_update()
                )
                if account is not None:
                    return as_user(account), False
            raise ServiceUnavailable(
                "The account changed. Try signing in again."
            )

    def get(self, user_id: str) -> User | None:
        """Read a detached API value without leaking ORM state."""
        try:
            account_id = UUID(user_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with transaction():
            account = db.session.get(Account, account_id)
            return as_user(account) if account else None
