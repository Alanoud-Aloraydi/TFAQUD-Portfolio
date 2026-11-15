"""The medicine reads, put together: plans and doses, derived, never
stored."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.medications.queries.latest_records import LatestRecords
from app.medications.queries.occurrences import Occurrences
from app.medications.queries.plan_lists import PlanLists
from app.medications.queries.plan_response import PlanResponse
from app.medications.queries.records import DoseRecords


class MedicationQueries(
    PlanLists,
    LatestRecords,
    PlanResponse,
    Occurrences,
    DoseRecords,
):
    """Read plans and derive scheduled occurrences without storing them."""

    def __init__(self, session: Session, now: datetime):
        """Read inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now
