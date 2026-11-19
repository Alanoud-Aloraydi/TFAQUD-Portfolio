"""The care service: every care workflow, each part in its own file,
run within the caller's transaction."""

from datetime import datetime

from sqlalchemy.orm import Session

from app.care.account_circles import CareAccountCircles
from app.care.account_deletion import CareAccountDeletion
from app.care.building import CareBuilding
from app.care.circle_changes import CareCircleChanges
from app.care.circle_limit import CareCircleLimit
from app.care.completion import CareCompletion
from app.care.consent import CareConsent
from app.care.creation import CareCreation
from app.care.invitation_changes import CareInvitationChanges
from app.care.invitations import CareInvitations
from app.care.locks import CareLocks
from app.care.members import CareMembers
from app.care.patient_basics import CarePatientBasics
from app.care.patient_profile import CarePatientProfile
from app.care.requests import CareRequests
from app.care.rules import CareRules


class CareService(
    CareLocks,
    CareRules,
    CareCircleLimit,
    CareMembers,
    CarePatientBasics,
    CareBuilding,
    CareCreation,
    CareRequests,
    CareConsent,
    CareCompletion,
    CareInvitations,
    CareInvitationChanges,
    CareCircleChanges,
    CarePatientProfile,
    CareAccountDeletion,
    CareAccountCircles,
):
    """Coordinate the six core entities using account-before-circle locks."""

    def __init__(self, session: Session, now: datetime):
        """Bind operations to a session and a consistent operation time."""
        self.session = session
        self.now = now
        # The other requests a new circle closed (`CareBuilding`).
        self.superseded_requests: list = []
