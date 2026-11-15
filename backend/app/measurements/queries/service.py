"""The measurement reads, put together: only the selected circle's
patient."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.measurements.queries.plan_list import PlanList
from app.measurements.queries.plan_reads import PlanReads
from app.measurements.queries.readings import Readings
from app.measurements.queries.task_item import TaskItem
from app.measurements.queries.task_reads import TaskReads
from app.measurements.queries.tasks import Tasks


class MeasurementQueries(
    PlanList,
    PlanReads,
    Tasks,
    TaskReads,
    TaskItem,
    Readings,
):
    """Read only data belonging to the selected circle's patient."""

    def __init__(self, session: Session, now: datetime):
        """Read inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now
