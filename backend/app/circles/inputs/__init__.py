"""Request bodies for the circle endpoints (see app/validation.py)."""

from app.circles.inputs.account import DeleteAccountInput
from app.circles.inputs.fields import (
    AppMode,
    CircleName,
    City,
    Flag,
    IsoDate,
    Latitude,
    Longitude,
    Name50,
    OtherText,
    TimeZone,
)
from app.circles.inputs.medical import (
    AllergiesInput,
    ConditionsInput,
    EmergencyContactInput,
    MedicalProfileInput,
)
from app.circles.inputs.members import (
    CircleRequestInput,
    EditAreasInput,
    InviteInput,
    LeaderInput,
    LeaveCircleInput,
    MemberAccessInput,
    RespondInput,
)
from app.circles.inputs.patient import (
    CompleteRequestInput,
    CreateOfflineCircleInput,
    CreateSelfCircleInput,
    PatientUpdateInput,
    RenameCircleInput,
)

__all__ = [
    "AllergiesInput",
    "AppMode",
    "CircleName",
    "CircleRequestInput",
    "City",
    "CompleteRequestInput",
    "ConditionsInput",
    "CreateOfflineCircleInput",
    "CreateSelfCircleInput",
    "DeleteAccountInput",
    "EditAreasInput",
    "EmergencyContactInput",
    "Flag",
    "InviteInput",
    "IsoDate",
    "Latitude",
    "LeaderInput",
    "LeaveCircleInput",
    "Longitude",
    "MedicalProfileInput",
    "MemberAccessInput",
    "Name50",
    "OtherText",
    "PatientUpdateInput",
    "RenameCircleInput",
    "RespondInput",
    "TimeZone",
]
