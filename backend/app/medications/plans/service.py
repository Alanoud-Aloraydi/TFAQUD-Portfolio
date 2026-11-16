"""The medicine plan service, put together: immutable versions, locked
with their patient and plan."""

from sqlalchemy.orm import Session

from app.medications.plans.changes import PlanChanges
from app.medications.plans.creation import PlanCreation
from app.medications.plans.lookup import PlanLookup
from app.medications.plans.restart import PlanRestart
from app.medications.plans.revision import PlanRevision
from app.medications.plans.revision_steps import PlanRevisionSteps


class MedicationPlanService(
    PlanCreation,
    PlanRevision,
    PlanRevisionSteps,
    PlanRestart,
    PlanChanges,
    PlanLookup,
):
    """Create immutable revisions while locking their patient and plan."""

    def __init__(self, session: Session, now):
        """Work inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now
