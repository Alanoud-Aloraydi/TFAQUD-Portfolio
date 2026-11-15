"""Building a complete circle: the patient, its first manager and its
leader in one step."""

from datetime import date
from uuid import UUID

from sqlalchemy import update

from app.errors import ValidationFailed
from app.models import (
    Account,
    CareCircle,
    CareCircleManager,
    CareCircleRequest,
)


class CareBuilding:
    """Builds a circle."""

    def _create_circle(
        self,
        name: str | None,
        birth_date: date,
        city: str,
        managers: set[UUID],
        patient_account: Account | None = None,
        leader: UUID | None = None,
        first_name: str | None = None,
        last_name: str | None = None,
        latitude: float | None = None,
        longitude: float | None = None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Build a complete circle before deferred constraints run.

        A patient with an account keeps the birth date and city on the
        account, and `name` is their own name for the circle; a patient
        without one keeps them on the circle, which has no name of its own.
        """
        if patient_account is not None and not (name or "").strip():
            raise ValidationFailed(
                "The circle name cannot be blank.", code="invalid_circle_name"
            )
        circle = CareCircle(
            name=name.strip() if patient_account is not None else None,
            account_id=patient_account.id if patient_account else None,
            # Whoever made the circle leads it while its patient does not
            # (`app.circles.leader`); alone, its one manager.
            leader_account_id=(
                leader if leader is not None else min(managers, default=None)
            ),
            time_zone=self._zone_for(time_zone),
            latitude=latitude,
            longitude=longitude,
        )
        self._check_patient_basics(circle, birth_date, city)
        if patient_account is not None:
            patient_account.birth_date = birth_date
            patient_account.city = city.strip()
        else:
            circle.first_name = first_name
            circle.last_name = last_name
            circle.birth_date = birth_date
            circle.city = city.strip()
        self.session.add(circle)
        self.session.flush()
        for manager_id in sorted(managers):
            self.session.add(
                CareCircleManager(
                    care_circle_id=circle.id, account_id=manager_id
                )
            )
        self.session.flush()
        # The patient has a circle now: their other open requests close.
        if patient_account:
            self.session.execute(
                update(CareCircleRequest)
                .where(
                    CareCircleRequest.patient_phone_number
                    == patient_account.phone_number,
                    CareCircleRequest.status.in_(
                        ["pending", "accepted"]
                    ),
                )
                .values(status="superseded")
            )
        return circle
