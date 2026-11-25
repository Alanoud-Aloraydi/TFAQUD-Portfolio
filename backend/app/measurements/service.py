"""The measurement service: plans and readings, written in the caller's
transaction."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.measurements.plans import PlanWrites
from app.measurements.readings import ReadingRecord


class MeasurementService(PlanWrites, ReadingRecord):
    """Own plan revisions and explicit readings in the caller's transaction."""

    def __init__(self, session: Session, now: datetime):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now
