"""Who may do what in a circle: the roles, the services that find an
account's role (`CircleAccess`), and the decorator endpoints use to
require one.

Every circle endpoint asks one question: "what is this user in this
circle?" `CircleAccess.role_in` answers it from the membership tables."""

import threading
from abc import ABC, abstractmethod
from enum import Enum
from functools import wraps
from uuid import UUID

from flask import g
from sqlalchemy import select

from app.auth.decorators import authenticate_request
from app.circles.leader import leader_id
from app.database import db, transaction
from app.errors import Forbidden
from app.extensions import get_circle_access
from app.models import Account, CareCircle, CareCircleManager


class CircleRole(str, Enum):
    """What a user is inside one care circle (TFQD-11).

    A user can be a Manager in one circle and a patient in another, so the role
    belongs to the (user, circle) pair, not to the user.
    """

    # A manager; a patient in the full app manages their own circle too.
    MANAGER = "manager"
    # A detailed-mode circle member whose owner paused editing access.
    MEMBER = "member"
    # A patient using Simplified Mode.
    SIMPLIFIED_PATIENT = "simplified_patient"


class CircleAccess(ABC):
    """Answers which role an account has in a circle (manager, simplified
    patient, ...), or none.
    """

    @abstractmethod
    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """The user's role in the circle; None if the user is not in it."""

    def can_edit(self, user_id: str, circle_id: str, area: str) -> bool:
        """Whether a manager may edit `area` («medications»,
        «measurements», «appointments») of the circle. Every manager may,
        unless the membership tables say otherwise."""
        return True


class DenyAllCircleAccess(CircleAccess):
    """The default. Nobody is a member of anything.

    The app fails closed: until the real membership lookup is connected, every
    circle endpoint refuses every request instead of allowing it by mistake.
    """

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """No role, ever."""
        return None


class InMemoryCircleAccess(CircleAccess):
    """A fixed table of memberships, for tests and local experiments."""

    def __init__(self):
        """No roles yet."""
        self._lock = threading.Lock()
        self._roles: dict[tuple[str, str], CircleRole] = {}

    def grant(self, user_id: str, circle_id: str, role: CircleRole) -> None:
        """Give the account this role in the circle (tests set up roles with
        it).
        """
        with self._lock:
            self._roles[(user_id, circle_id)] = role

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """The role given to the account in the circle, or None."""
        with self._lock:
            return self._roles.get((user_id, circle_id))


class PostgresCircleAccess(CircleAccess):
    """Detailed patients have management and retain patient identity."""

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """Return effective access only within the requested circle."""
        # An id that is not a UUID is no member.
        try:
            account_id, care_circle_id = UUID(user_id), UUID(circle_id)
        except (ValueError, TypeError, AttributeError):
            return None
        with transaction():
            # A manager (a patient in the full app manages their own circle):
            # one the leader let edit nothing is a member who only reads.
            membership = self._membership(account_id, care_circle_id)
            if membership is not None:
                return (
                    CircleRole.MANAGER
                    if membership.can_edit_any
                    or self._leads(account_id, care_circle_id)
                    else CircleRole.MEMBER
                )
            # Else the circle's patient in the simplified mode.
            mode = db.session.scalar(
                select(Account.app_mode)
                .join(CareCircle, CareCircle.account_id == Account.id)
                .where(
                    Account.id == account_id,
                    CareCircle.id == care_circle_id,
                )
            )
            if mode == "simplified":
                return CircleRole.SIMPLIFIED_PATIENT
            return None

    def can_edit(self, user_id: str, circle_id: str, area: str) -> bool:
        """Whether the account may edit `area` of the circle: the leader
        always; another member when the leader allows it."""
        try:
            account_id, care_circle_id = UUID(user_id), UUID(circle_id)
        except (ValueError, TypeError, AttributeError):
            return False
        with transaction():
            membership = self._membership(account_id, care_circle_id)
            if membership is None:
                # The simplified patient edits nothing but their own day.
                return False
            return membership.may_edit(area) or self._leads(
                account_id, care_circle_id
            )

    @staticmethod
    def _membership(
        account_id: UUID, care_circle_id: UUID
    ) -> CareCircleManager | None:
        return db.session.scalar(
            select(CareCircleManager).where(
                CareCircleManager.account_id == account_id,
                CareCircleManager.care_circle_id == care_circle_id,
            )
        )

    @staticmethod
    def _leads(account_id: UUID, care_circle_id: UUID) -> bool:
        circle = db.session.get(CareCircle, care_circle_id)
        return circle is not None and leader_id(db.session, circle) == (
            account_id
        )


def current_circle_role() -> CircleRole:
    """The role the asking account has in the circle of this request."""
    return g.circle_role


def require_circle_role(*allowed: CircleRole, area: str | None = None):
    """Allow the endpoint only to a signed-in account with one of the
    `allowed` roles in the URL's circle; anyone else gets 403.

    With an `area` («medications», «measurements», «appointments»), a
    manager the circle's leader does not let edit that area counts as a
    member who only reads (`app.circles.leader`).
    """
    def decorator(view):
        """Wrap one endpoint with the role check."""
        @wraps(view)
        def wrapper(*args, **kwargs):
            """Check the sign-in and the role in the circle, keep the role for
            the endpoint, then run it.
            """
            auth = authenticate_request()
            if "circle_id" not in kwargs:
                # A mistake in the code, not in the request.
                raise RuntimeError(
                    "require_circle_role needs a <circle_id> in the URL."
                )
            access = get_circle_access()
            role = access.role_in(auth.user_id, kwargs["circle_id"])
            if (
                area is not None
                and role == CircleRole.MANAGER
                and not access.can_edit(
                    auth.user_id, kwargs["circle_id"], area
                )
            ):
                role = CircleRole.MEMBER
            # Not a member and wrong role give the same answer, so a caller can
            # not learn which circles exist.
            if role is None or (allowed and role not in allowed):
                raise Forbidden("You do not have access to this circle.")
            g.circle_role = role
            return view(*args, **kwargs)

        return wrapper

    return decorator
