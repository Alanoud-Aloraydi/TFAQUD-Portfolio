"""Making a circle: the patient's birth date, city and zone checked and
filled in, and the patient, its first manager and its leader built in one
step, either at once (self-care, or for a patient without an account) or
when an accepted request is completed.

Where the app's Saudi cities are, for the patient's weather on «اليوم»
(the phone's own location is never asked for)."""

from datetime import date
from uuid import UUID

from sqlalchemy import func, true, update

from app.clock import DEFAULT_ZONE, is_zone, patient_today, require_old_enough
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
        time_zone: str | None = None,
        completing: UUID | None = None,
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
        # The patient has a circle now: their other open requests close, as
        # answered by them now, so «السابقة» shows them with the reason and
        # each sender is told (`superseded_requests`, read by the route).
        self.superseded_requests = []
        if patient_account:
            request = CareCircleRequest
            self.superseded_requests = list(self.session.scalars(
                update(request)
                .where(
                    request.patient_phone_number
                    == patient_account.phone_number,
                    request.status.in_(["pending", "accepted"]),
                    request.id != completing if completing else true(),
                )
                .values(
                    status="superseded",
                    responded_at=func.coalesce(request.responded_at, self.now),
                    responded_by_account_id=func.coalesce(
                        request.responded_by_account_id, patient_account.id
                    ),
                )
                .returning(request.id)
            ))
        return circle

    # Checks the basics every patient has.
    def _check_patient_basics(
        self, circle: CareCircle, birth_date: date, city: str
    ) -> None:
        """Birth date, city and zone are required for every patient.

        Runs on the values as they will be saved (on the circle, or on the
        patient's account): the birth date is checked against the day in
        the patient's own zone, as the app's date sheet counts it there."""
        if not city.strip():
            raise ValidationFailed(
                "The city cannot be blank.", code="invalid_city"
            )
        if not is_zone(circle.time_zone):
            raise ValidationFailed(
                "The time zone is not a known IANA zone.",
                code="invalid_time_zone",
            )
        if birth_date > patient_today(circle, self.now):
            raise ValidationFailed(
                "The birth date cannot be in the future.",
                code="invalid_birth_date",
            )
        # A patient with an account holds it, so is 15 or older.
        if circle.account_id is not None:
            require_old_enough(birth_date, patient_today(circle, self.now))

    @staticmethod
    def _zone_for(time_zone: str | None, current: str | None = None) -> str:
        """The patient's zone: the one sent, else the one saved, else
        `DEFAULT_ZONE`.

        The app sends the zone with every city: Saudi Arabia's for a city
        of its Saudi list, the phone's for a city typed by hand, and the
        person can change it later. An app older than zones sends none and
        offers only the Saudi list, so its patients live by DEFAULT_ZONE."""
        return time_zone or current or DEFAULT_ZONE

    @staticmethod
    def _own_basics(
        account: Account, birth_date: date | None, city: str | None
    ) -> tuple[date, str]:
        """The patient's birth date and city when the patient is the caller.

        What the request sends wins; what it leaves out comes from the
        account (onboarding saves both). An account made before onboarding
        asked for them has neither, and then the request must send them.
        """
        birth_date = birth_date or account.birth_date
        city = city or account.city
        if birth_date is None:
            raise ValidationFailed(
                "Add your birth date first.", code="birth_date_required"
            )
        if city is None:
            raise ValidationFailed(
                "Add your city first.", code="city_required"
            )
        return birth_date, city

    # Makes a circle at once.
    def create_self(
        self,
        actor_id: UUID,
        name: str,
        birth_date: date | None,
        city: str | None,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Create self-care with both patient identity and management."""
        account = self._lock_accounts(actor_id)[actor_id]
        birth_date, city = self._own_basics(account, birth_date, city)
        self._assign_app_mode(account, "detailed")
        self._require_no_patient(actor_id)
        self._require_room_for_circle(actor_id)
        return self._create_circle(
            name,
            birth_date,
            city,
            {actor_id},
            patient_account=account,
            time_zone=time_zone,
        )

    def create_without_account(
        self,
        actor_id: UUID,
        first_name: str,
        last_name: str,
        birth_date: date,
        city: str,
        time_zone: str | None = None,
    ) -> CareCircle:
        """Create a care circle for a patient without an account.

        Nobody chooses its name: everyone sees «دائرة» and the patient's
        first name (`app.circles.naming`), so the circle stores none.
        """
        # The asker manages in the detailed mode, and the patient needs both
        # names.
        account = self._lock_accounts(actor_id)[actor_id]
        self._assign_app_mode(account, "detailed")
        if not first_name.strip() or not last_name.strip():
            raise ValidationFailed(
                "Both patient names are required.",
                code="patient_name_required",
            )
        self._require_room_for_circle(actor_id)
        return self._create_circle(
            None,
            birth_date,
            city,
            {actor_id},
            first_name=first_name.strip(),
            last_name=last_name.strip(),
            time_zone=time_zone,
        )
