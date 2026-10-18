"""The authorization interface for circles.

Every circle endpoint asks one question: "what is this user in this circle?"
`CircleAccess.role_in` answers it. The real answer comes from the membership
tables (TFQD-7), so this task defines only the question and two simple answers.
"""

import threading
from abc import ABC, abstractmethod

from app.authz.roles import CircleRole


class CircleAccess(ABC):
    @abstractmethod
    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        """The user's role in the circle, or None if the user is not a member."""


class DenyAllCircleAccess(CircleAccess):
    """The default. Nobody is a member of anything.

    The app fails closed: until the real membership lookup is connected, every
    circle endpoint refuses every request instead of allowing it by mistake.
    """

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        return None


class InMemoryCircleAccess(CircleAccess):
    """A fixed table of memberships, for tests and local experiments."""

    def __init__(self):
        self._lock = threading.Lock()
        self._roles: dict[tuple[str, str], CircleRole] = {}

    def grant(self, user_id: str, circle_id: str, role: CircleRole) -> None:
        with self._lock:
            self._roles[(user_id, circle_id)] = role

    def role_in(self, user_id: str, circle_id: str) -> CircleRole | None:
        with self._lock:
            return self._roles.get((user_id, circle_id))
