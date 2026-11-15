"""The medical file service, put together: the profile and the
emergency contacts, locked by circle."""

from app.care import CareService
from app.medical.access import MedicalAccess
from app.medical.contact_checks import ContactChecks
from app.medical.contacts import Contacts
from app.medical.profile_read import ProfileRead
from app.medical.profile_rows import ProfileRows
from app.medical.profile_update import ProfileUpdate


class MedicalService(
    MedicalAccess,
    ProfileRead,
    ProfileUpdate,
    ProfileRows,
    Contacts,
    ContactChecks,
    CareService,
):
    """Medical profile and emergency contacts, with circle-level locking."""
