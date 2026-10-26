"""Resolve access from independent patient and manager relationships."""

from uuid import UUID

from sqlalchemy import select

from app.authz.circle_access import CircleAccess
from app.authz.roles import CircleRole
from app.database import db
from app.models import Account, CareCircleManager, Patient


class PostgresCircleAccess(CircleAccess):
    """Detailed patients have management and retain patient identity."""

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """Return effective access only within the requested circle."""
        try:
            account_id, care_circle_id = UUID(user_id), UUID(circle_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with db.session.begin():
            manager = db.session.scalar(
                select(CareCircleManager.id).where(
                    CareCircleManager.account_id == account_id,
                    CareCircleManager.care_circle_id == care_circle_id,
                )
            )
            if manager is not None:
                return CircleRole.MANAGER
            mode = db.session.scalar(
                select(Account.app_mode)
                .join(
                    Patient,
                    Patient.account_id == Account.id,
                )
                .where(
                    Account.id == account_id,
                    Patient.care_circle_id == care_circle_id,
                )
            )
            if mode == "simplified":
                return CircleRole.SIMPLIFIED_PATIENT
            return None
