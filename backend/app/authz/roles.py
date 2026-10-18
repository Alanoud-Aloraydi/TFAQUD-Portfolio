from enum import Enum


class CircleRole(str, Enum):
    """What a user is inside one care circle (TFQD-11).

    A user can be a Manager in one circle and a patient in another, so the role
    belongs to the (user, circle) pair, not to the user.
    """

    MANAGER = "manager"
    PATIENT = "patient"  # a patient who uses the full app for themselves
    SIMPLIFIED_PATIENT = "simplified_patient"  # a patient using Simplified Mode
