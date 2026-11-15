"""The measurement service, put together: plans and readings, written
in the caller's transaction."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.measurements.service.follow_up import FollowUp
from app.measurements.service.plan_revision import PlanRevision
from app.measurements.service.plan_versions import PlanVersions
from app.measurements.service.plan_writes import PlanWrites
from app.measurements.service.reading_record import ReadingRecord
from app.measurements.service.reading_task import ReadingTask


class MeasurementService(
    PlanWrites,
    PlanRevision,
    PlanVersions,
    ReadingRecord,
    ReadingTask,
    FollowUp,
):
    """Own plan revisions and explicit readings in the caller's transaction."""

    def __init__(self, session: Session, now: datetime):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now
