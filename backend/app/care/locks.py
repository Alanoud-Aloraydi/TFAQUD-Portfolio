"""Locking the accounts and the circle a care workflow changes, and
reading its rows again under the lock."""

from uuid import UUID

from sqlalchemy import select

from app.errors import NotFound
from app.models import (
    Account,
    CareCircle,
    CareCircleInvitation,
    CareCircleRequest,
)


class CareLocks:
    """Locks rows in a stable order and reads them again."""

    def _lock_accounts(self, *account_ids: UUID) -> dict[UUID, Account]:
        """Lock accounts in stable order and refresh previously read values."""
        accounts = self.session.scalars(
            select(Account)
            .where(Account.id.in_(set(account_ids)))
            .order_by(Account.id)
            .with_for_update()
            .execution_options(populate_existing=True)
        ).all()
        if len(accounts) != len(set(account_ids)):
            raise NotFound("An account does not exist.")
        return {account.id: account for account in accounts}

    def _lock_circle(self, circle_id: UUID) -> CareCircle:
        """Serialize lifecycle operations on an existing circle."""
        circle = self.session.get(
            CareCircle, circle_id, with_for_update=True, populate_existing=True
        )
        if circle is None:
            raise NotFound("The care circle does not exist.")
        return circle

    def _get_circle(self, circle_id: UUID) -> CareCircle:
        """Return the circle (which is its patient) or raise NotFound."""
        circle = self.session.get(CareCircle, circle_id)
        if circle is None:
            raise NotFound("The care circle does not exist.")
        return circle

    def _get_creation_request(
        self, request_id: UUID, *, lock: bool = False
    ) -> CareCircleRequest:
        """Refresh a circle request and reject a concurrently deleted row."""
        request = self.session.get(
            CareCircleRequest,
            request_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if request is None:
            raise NotFound("The circle request does not exist.")
        return request

    def _get_invitation(
        self, invitation_id: UUID, *, lock: bool = False
    ) -> CareCircleInvitation:
        """Refresh an invitation and reject a missing row."""
        invitation = self.session.get(
            CareCircleInvitation,
            invitation_id,
            with_for_update=lock,
            populate_existing=True,
        )
        if invitation is None:
            raise NotFound("The invitation does not exist.")
        return invitation
