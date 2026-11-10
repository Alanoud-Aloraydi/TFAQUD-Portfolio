"""The roles an account can have in a care circle."""

from enum import Enum


class CircleRole(str, Enum):
    """What a user is inside one care circle (TFQD-11).

    A user can be a Manager in one circle and a patient in another, so the role
    belongs to the (user, circle) pair, not to the user.
    """

    # A manager; a patient in the full app manages their own circle too.
    MANAGER = "manager"
    # A patient using Simplified Mode.
    SIMPLIFIED_PATIENT = "simplified_patient"
