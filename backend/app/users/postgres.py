"""PostgreSQL adapter preserving the existing user-facing API contract."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert

from app.database import db
from app.errors import ServiceUnavailable
from app.models import Account
from app.users.store import User, UserStore

_CREATION_ATTEMPTS = 3


def as_user(account: Account) -> User:
    """Keep API fields and compact IDs outside persistence."""
    return User(
        id=account.id.hex,
        phone=account.phone_number,
        created_at=account.created_at,
        first_name=account.first_name,
        last_name=account.last_name,
        display_name=account.display_name,
    )


class PostgresUserStore(UserStore):
    """Own one short transaction per existing account-store operation."""

    def get_or_create_by_phone(
        self, phone: str, now: datetime
    ) -> tuple[User, bool]:
        """Use database uniqueness, including concurrent first sign-ins."""
        with db.session.begin():
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
        with db.session.begin():
            account = db.session.get(Account, account_id)
            return as_user(account) if account else None

    def update_profile(
        self, user_id: str, first_name: str, last_name: str, display_name: str
    ) -> User | None:
        """Replace the complete name group in one transaction."""
        try:
            account_id = UUID(user_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with db.session.begin():
            account = db.session.get(Account, account_id, with_for_update=True)
            if account is None:
                return None
            account.first_name = first_name
            account.last_name = last_name
            account.display_name = display_name
            db.session.flush()
            return as_user(account)
