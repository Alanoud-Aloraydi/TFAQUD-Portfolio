"""The bodies about the patient and the circle: its basics, making it,
changing and renaming it."""

from pydantic import model_validator
from pydantic_core import PydanticCustomError

from app.circles.inputs.fields import (
    CircleName,
    City,
    IsoDate,
    Latitude,
    Longitude,
    Name50,
    TimeZone,
)
from app.circles.inputs.medical import MedicalProfileInput
from app.validation import Dto


class _Point(Dto):
    """The optional point the app got from the phone's location."""

    latitude: Latitude | None = None
    longitude: Longitude | None = None

    @model_validator(mode="after")
    def _both_or_neither(self):
        """Refuse a latitude without a longitude, or the other way round."""
        if (self.latitude is None) != (self.longitude is None):
            raise PydanticCustomError(
                "incomplete_location",
                "Send both latitude and longitude, or neither.",
            )
        return self


class _Place(_Point):
    """City plus the optional point, and the city's IANA zone (left out by
    an app older than zones; see `CareService._zone_for`)."""

    city: City
    time_zone: TimeZone | None = None


class _PatientBasics(_Place):
    """A patient who is not the caller: city, birth date, optional point and
    medical profile.
    """

    birth_date: IsoDate
    medical_profile: MedicalProfileInput | None = None


class _OwnBasics(_Point):
    """The patient is the caller: a birth date or city left out is read
    from the account, where onboarding saved it."""

    birth_date: IsoDate | None = None
    city: City | None = None
    time_zone: TimeZone | None = None
    medical_profile: MedicalProfileInput | None = None


class CreateSelfCircleInput(_OwnBasics):
    """The body of creating one's own circle (the caller is the patient)."""

    name: CircleName


class CreateOfflineCircleInput(_PatientBasics):
    """The body of creating a circle for a patient without an account."""

    # Not used: the circle is named «دائرة» and the patient's first name.
    # An older app still sends it.
    name: CircleName | None = None
    patient_first_name: Name50
    patient_last_name: Name50


class CompleteRequestInput(_OwnBasics):
    """The body of the patient accepting a request to make their circle."""

    # The patient's own name for the circle; only they see it. An older app
    # sends none, and the circle is then «دائرتي».
    name: CircleName | None = None


class PatientUpdateInput(_Place):
    """The body of changing the patient's details."""

    birth_date: IsoDate
    first_name: Name50 | None = None
    last_name: Name50 | None = None


class RenameCircleInput(Dto):
    """The body of renaming a circle."""

    name: CircleName
