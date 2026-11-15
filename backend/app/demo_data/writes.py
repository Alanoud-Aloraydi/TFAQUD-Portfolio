"""Writing the demo through the app's own services: medicines,
measurements, readings and appointments."""

from app.appointments.inputs import AppointmentRequest
from app.appointments.service import AppointmentService
from app.measurements.inputs import PlanRequest as MeasurementPlanRequest
from app.measurements.inputs import ReadingRequest
from app.measurements.service import MeasurementService
from app.medications.inputs import PlanRequest, RevisePlanRequest
from app.medications.plans import MedicationPlanService
from app.models import MedicationPlan


class DemoWrites:
    """Writes through the services."""

    def create(self, actor, circle, body, when) -> MedicationPlan:
        """Add a demo medicine, as added at `when`."""
        plan = MedicationPlanService(self.session, when).create(
            circle.id, actor.id, PlanRequest.model_validate(body)
        )
        self.summary.plans += 1
        return plan

    def revise(self, actor, circle, plan, version, body, effective, when):
        """Edit a demo medicine, as edited at `when`, from `effective` on."""
        MedicationPlanService(self.session, when).revise(
            circle.id,
            plan.id,
            actor.id,
            RevisePlanRequest.model_validate(
                {
                    **body,
                    "expected_version_number": version,
                    "effective_from_on": effective,
                }
            ),
        )
        self.summary.revisions += 1

    def measure(self, actor, circle, body) -> None:
        """Add a demo measurement plan."""
        MeasurementService(self.session, self.now).create(
            circle.id, actor.id, MeasurementPlanRequest.model_validate(body)
        )

    def reading(self, actor, circle, body) -> None:
        """Record one demo reading, at the moment the body names."""
        MeasurementService(self.session, self.now).record(
            circle.id, actor.id, ReadingRequest.model_validate(body)
        )

    def appointment(self, actor, circle, body) -> None:
        """Add a demo appointment."""
        AppointmentService(self.session, self.now).create(
            circle.id, actor.id, AppointmentRequest.model_validate(body)
        )
