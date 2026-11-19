"""At most MAX_CIRCLES circles per person."""

from uuid import UUID

from sqlalchemy import and_, func, or_, select

from app.errors import ValidationFailed
from app.models import CareCircle, CareCircleManager, CareCircleRequest

# The circles a person can be in at once, counting the requests that may
# still become one.
MAX_CIRCLES = 6


class CareCircleLimit:
    """Refuses a seventh circle."""

    def _require_room_for_circle(self, account_id: UUID) -> None:
        """Count the circles the account manages or is the patient of, and
        the requests it sent or accepted that are still open; refuse when
        they already make MAX_CIRCLES. Call it after locking the account."""
        circles = set(
            self.session.scalars(
                select(CareCircleManager.care_circle_id).where(
                    CareCircleManager.account_id == account_id
                )
            )
        )
        circles.update(
            self.session.scalars(
                select(CareCircle.id).where(
                    CareCircle.account_id == account_id
                )
            )
        )
        waiting = self.session.scalar(
            select(func.count()).select_from(CareCircleRequest).where(
                or_(
                    and_(
                        CareCircleRequest.requested_by_account_id
                        == account_id,
                        CareCircleRequest.status.in_(["pending", "accepted"]),
                    ),
                    and_(
                        CareCircleRequest.responded_by_account_id
                        == account_id,
                        CareCircleRequest.status == "accepted",
                    ),
                )
            )
        )
        if len(circles) + (waiting or 0) >= MAX_CIRCLES:
            raise ValidationFailed(
                f"A person can be in at most {MAX_CIRCLES} circles.",
                code="too_many_circles",
            )
