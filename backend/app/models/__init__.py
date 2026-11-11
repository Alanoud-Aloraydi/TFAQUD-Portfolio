"""Persistence models registered with SQLAlchemy metadata."""
from app.models.account import Account
from app.models.auth import AccountSession, OtpRequest, OtpSend
from app.models.circle import CareCircle
from app.models.manager import CareCircleManager
from app.models.circle_request import CareCircleInvitation, CareCircleRequest
from app.models.medical import EmergencyContact, PatientAllergy
from app.models.medical import PatientCondition
from app.models.medication_dose_record import MedicationDoseRecord
from app.models.medication_plan import MedicationPlan, MedicationPlanVersion
from app.models.medication_schedule import (
    MedicationSchedule,
    MedicationScheduleDay,
    MedicationScheduleMonthDay,
)
from app.models.measurement import (
    MeasurementPlan,
    MeasurementPlanTime,
    MeasurementPlanVersion,
    MeasurementPlanWeekday,
    MeasurementReading,
    MeasurementTarget,
)
from app.models.appointment import (
    Appointment,
    AppointmentCompanion,
    AppointmentVisit,
)
from app.models.push import PushDevice
from app.models.notification_log import NotificationLog
from app.models.photo import AccountPhoto, CareCirclePhoto
from app.models.photo import MedicationPlanPhoto
from app.models.task_snooze import TaskSnooze

__all__ = [
    "Account",
    "AccountPhoto",
    "AccountSession",
    "OtpRequest",
    "OtpSend",
    "CareCircle",
    "CareCircleInvitation",
    "CareCircleManager",
    "CareCircleRequest",
    "CareCirclePhoto",
    "EmergencyContact",
    "PatientAllergy",
    "PatientCondition",
    "MedicationPlan",
    "MedicationPlanPhoto",
    "MedicationPlanVersion",
    "MedicationSchedule",
    "MedicationScheduleDay",
    "MedicationScheduleMonthDay",
    "MedicationDoseRecord",
    "MeasurementPlan",
    "MeasurementPlanTime",
    "MeasurementPlanVersion",
    "MeasurementPlanWeekday",
    "MeasurementReading",
    "TaskSnooze",
    "MeasurementTarget",
    "Appointment",
    "AppointmentCompanion",
    "AppointmentVisit",
    "PushDevice",
    "NotificationLog",
    "TaskSnooze",
]
