"""Resolve access from independent patient and manager relationships."""

from uuid import UUID

from sqlalchemy import select

from app.authz.circle_access import CircleAccess
from app.authz.roles import CircleRole
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
            # A manager (a patient in the full app manages their own circle).
            membership = db.session.scalar(
                select(CareCircleManager.can_edit).where(
                    CareCircleManager.account_id == account_id,
                    CareCircleManager.care_circle_id == care_circle_id,
                )
            )
            if membership is not None:
                return (
                    CircleRole.MANAGER if membership else CircleRole.MEMBER
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
