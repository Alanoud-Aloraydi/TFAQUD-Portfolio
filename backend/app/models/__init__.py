"""Every table of the database, as SQLAlchemy models.

Importing this package registers all of them with the metadata that the
migrations and `flask db` compare against."""

from app.models.account import Account, AccountSession, OtpRequest, OtpSend
from app.models.appointment import (
    Appointment,
    AppointmentCompanion,
    AppointmentVisit,
)
from app.models.circle import CareCircle, CareCircleManager
from app.models.circle_request import CareCircleInvitation, CareCircleRequest
from app.models.measurement import (
    MeasurementPlan,
    MeasurementPlanTime,
    MeasurementPlanVersion,
    MeasurementPlanWeekday,
)
from app.models.measurement_reading import MeasurementReading
from app.models.medical import (
    EmergencyContact,
    PatientAllergy,
    PatientCondition,
)
from app.models.medication import (
    MedicationPlan,
    MedicationPlanVersion,
    MedicationSchedule,
    MedicationScheduleDay,
    MedicationScheduleMonthDay,
)
from app.models.medication_dose import (
    MedicationDoseRecord,
    MedicationExtraDose,
)
from app.models.notification import NotificationLog, TaskSnooze
from app.models.photo import (
    AccountPhoto,
    CareCirclePhoto,
    MedicationPlanPhoto,
)

__all__ = [
    "Account",
    "AccountPhoto",
    "AccountSession",
    "Appointment",
    "AppointmentCompanion",
    "AppointmentVisit",
    "CareCircle",
    "CareCircleInvitation",
    "CareCircleManager",
    "CareCirclePhoto",
    "CareCircleRequest",
    "EmergencyContact",
    "MeasurementPlan",
    "MeasurementPlanTime",
    "MeasurementPlanVersion",
    "MeasurementPlanWeekday",
    "MeasurementReading",
    "MedicationDoseRecord",
    "MedicationExtraDose",
    "MedicationPlan",
    "MedicationPlanPhoto",
    "MedicationPlanVersion",
    "MedicationSchedule",
    "MedicationScheduleDay",
    "MedicationScheduleMonthDay",
    "NotificationLog",
    "OtpRequest",
    "OtpSend",
    "PatientAllergy",
    "PatientCondition",
    "TaskSnooze",
]
