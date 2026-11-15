"""The bodies of editing a medicine and of cancelling an edit."""

from datetime import date
from typing import Annotated

from pydantic import Field

from app.medications.inputs.plan import PlanRequest
from app.validation import Dto


class RevisePlanRequest(PlanRequest):
    """The body of editing a medicine: the same as adding one, plus the version
    it was read from and the day the edit starts.
    """

    expected_version_number: Annotated[int, Field(ge=1)]
    effective_from_on: date | None = None


class CancelPendingRequest(Dto):
    """The body of cancelling an edit that has not started: the version it was
    read from.
    """

    expected_version_number: Annotated[int, Field(ge=1)]
