"""Persistence models registered with SQLAlchemy metadata."""

from app.models.account import Account
from app.models.auth import AccountSession, OtpChallenge, OtpSendAttempt
from app.models.circle import CareCircle
from app.models.patient import Patient
from app.models.manager import CareCircleManager
from app.models.creation_request import CareCircleCreationRequest
from app.models.invitation import CareCircleManagerInvitation
from app.models.medical import EmergencyContact, PatientAllergy
from app.models.medical import PatientCondition
from app.models.medication_dose_record import MedicationDoseRecord
from app.models.medication_plan import MedicationPlan, MedicationPlanVersion
from app.models.medication_schedule import (
    MedicationSchedule,
    MedicationScheduleDay,
)

__all__ = [
    "Account",
    "AccountSession",
    "OtpChallenge",
    "OtpSendAttempt",
    "CareCircle",
    "Patient",
    "CareCircleManager",
    "CareCircleCreationRequest",
    "CareCircleManagerInvitation",
    "EmergencyContact",
    "PatientAllergy",
    "PatientCondition",
    "MedicationPlan",
    "MedicationPlanVersion",
    "MedicationSchedule",
    "MedicationScheduleDay",
    "MedicationDoseRecord",
]
