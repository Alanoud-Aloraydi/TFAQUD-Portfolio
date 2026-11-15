"""The medicine plans of a circle, and one plan, as the app reads them."""

from uuid import UUID

from sqlalchemy import select

from app.errors import NotFound
from app.models import MedicationPlan, MedicationPlanVersion


class PlanLists:
    """Lists plans and reads one."""

    def plans(self, circle_id: UUID) -> list[dict]:
        """Every medicine of the circle's patient, as the app reads them."""
        patient = self._patient(circle_id)
        # Every version of each medicine (cancelled ones left out), grouped by
        # medicine.
        rows = self.session.execute(
            select(MedicationPlan, MedicationPlanVersion)
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .where(
                MedicationPlan.care_circle_id == patient.id,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
        grouped = {}
        for plan, version in rows:
            grouped.setdefault(plan.id, (plan, []))[1].append(version)
        # Each medicine as the app reads it, with its latest dose; the ones in
        # use first, by name.
        result = [
            self._plan_response(patient, plan, versions)
            for plan, versions in grouped.values()
        ]
        last_records = self._latest_records(patient.id)
        for item in result:
            item["last_record"] = last_records.get(item["id"])
        return sorted(
            result,
            key=lambda item: (
                item["stopped_at"] is not None,
                item["version"]["name"],
                item["id"],
            ),
        )

    def plan(self, circle_id: UUID, plan_id: UUID) -> dict:
        """One medicine of the circle's patient, as the app reads it; 404 for
        another patient's.
        """
        # The medicine's versions (cancelled ones left out), only for this
        # circle's patient.
        patient = self._patient(circle_id)
        rows = self.session.execute(
            select(MedicationPlan, MedicationPlanVersion)
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .where(
                MedicationPlan.id == plan_id,
                MedicationPlan.care_circle_id == patient.id,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        ).all()
        if not rows:
            raise NotFound("The medication plan does not exist.")
        return self._plan_response(
            patient, rows[0][0], [row[1] for row in rows]
        )
