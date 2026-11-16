"""The patient's birth date, city and zone, checked and filled in."""

from datetime import date

from app.clock import DEFAULT_ZONE, is_zone, patient_today
from app.errors import ValidationFailed
from app.models import Account, CareCircle


class CarePatientBasics:
    """Checks the basics every patient has."""

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
