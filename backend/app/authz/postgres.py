"""Resolve access from independent patient and manager relationships."""

from uuid import UUID

from sqlalchemy import select

from app.authz.circle_access import CircleAccess
from app.authz.roles import CircleRole
from app.circles.leader import leader_id
from app.database import db, transaction
from app.models import Account, CareCircle, CareCircleManager


class PostgresCircleAccess(CircleAccess):
    """Detailed patients have management and retain patient identity."""

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """Return effective access only within the requested circle."""
        # An id that is not a UUID is no member.
        try:
            account_id, care_circle_id = UUID(user_id), UUID(circle_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with transaction():
            # A manager (a patient in the full app manages their own circle):
            # one the leader let edit nothing is a member who only reads.
            membership = self._membership(account_id, care_circle_id)
            if membership is not None:
                return (
                    CircleRole.MANAGER
                    if membership.can_edit_any
                    or self._leads(account_id, care_circle_id)
                    else CircleRole.MEMBER
                )
            # Else the circle's patient in the simplified mode.
            mode = db.session.scalar(
                select(Account.app_mode)
                .join(CareCircle, CareCircle.account_id == Account.id)
                .where(
                    Account.id == account_id,
                    CareCircle.id == care_circle_id,
                )
            )
            if mode == "simplified":
                return CircleRole.SIMPLIFIED_PATIENT
            return None

    def can_edit(self, user_id: str, circle_id: str, area: str) -> bool:
        """Whether the account may edit `area` of the circle: the leader
        always; another member when the leader allows it."""
        try:
            account_id, care_circle_id = UUID(user_id), UUID(circle_id)
        except (ValueError, TypeError, AttributeError):
            return False
        with transaction():
            membership = self._membership(account_id, care_circle_id)
            if membership is None:
                # The simplified patient edits nothing but their own day.
                return False
            return membership.may_edit(area) or self._leads(
                account_id, care_circle_id
            )

    @staticmethod
    def _membership(
        account_id: UUID, care_circle_id: UUID
    ) -> CareCircleManager | None:
        return db.session.scalar(
            select(CareCircleManager).where(
                CareCircleManager.account_id == account_id,
                CareCircleManager.care_circle_id == care_circle_id,
            )
        )

    @staticmethod
    def _leads(account_id: UUID, care_circle_id: UUID) -> bool:
        circle = db.session.get(CareCircle, care_circle_id)
        return circle is not None and leader_id(db.session, circle) == (
            account_id
        )
