"""Medicine reads: the plans of a circle and one plan as the app reads
them, the doses of some days, and their records; derived, never
stored."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.clock import patient_today
from app.errors import NotFound
from app.medications.occurrences import Occurrences
from app.medications.views import plan_response, schedule_responses
from app.models import (
    CareCircle,
    MedicationDoseRecord,
    MedicationPlan,
    MedicationPlanVersion,
)


class MedicationQueries(Occurrences):
    """Read plans and derive scheduled occurrences without storing them."""

    def __init__(self, session: Session, now: datetime):
        """Read inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    # Lists plans and reads one.
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

    # Writes a plan for the API.
    def _plan_response(self, patient, plan, versions) -> dict:
        """Show the active, pending, and completed versions separately,
        as of the patient's today."""
        today = patient_today(patient, self.now)
        active = [v for v in versions if v.effective_from_on <= today]
        version = (
            max(active, key=lambda item: item.version_number)
            if active else min(versions, key=lambda item: item.version_number)
        )
        pending = [
            v for v in versions
            if v.effective_from_on > today and v.id != version.id
        ]
        result = plan_response(plan, version)
        creator_id = plan.created_by_account_id
        editor_id = version.created_by_account_id
        accounts = accounts_by_id(
            self.session,
            {id for id in (creator_id, editor_id) if id is not None},
        )
        result["created_by"] = recorder_response(accounts.get(creator_id))
        # Who made the version in effect now — the same person as
        # created_by unless the plan was revised since.
        result["last_edited_by"] = recorder_response(accounts.get(editor_id))
        result["version"]["schedules"] = schedule_responses(
            self.session, version.id
        )
        result["history"] = []
        for earlier in sorted(versions, key=lambda item: item.version_number):
            if earlier.effective_from_on > today:
                continue
            item = plan_response(plan, earlier)["version"]
            item["schedules"] = schedule_responses(self.session, earlier.id)
            result["history"].append(item)
        if pending:
            future = max(pending, key=lambda item: item.version_number)
            result["pending_version"] = plan_response(
                plan, future
            )["version"]
            result["pending_version"]["schedules"] = schedule_responses(
                self.session, future.id
            )
        return result

    # Reads the patient and the recorded doses.
    def _patient(self, circle_id: UUID) -> CareCircle:
        """The circle's patient; 404 when there is none."""
        patient = self.session.scalar(
            select(CareCircle).where(CareCircle.id == circle_id)
        )
        if patient is None:
            raise NotFound("The patient does not exist.")
        return patient

    def _records(
        self,
        schedule_ids: set[UUID],
        from_date: date,
        to_date: date,
    ) -> dict[tuple[UUID, date], MedicationDoseRecord]:
        """The dose records of these schedules between the two dates, by
        schedule and day.
        """
        if not schedule_ids:
            return {}
        rows = self.session.scalars(
            select(MedicationDoseRecord).where(
                MedicationDoseRecord.schedule_id.in_(schedule_ids),
                MedicationDoseRecord.scheduled_on.between(
                    from_date, to_date
                ),
            )
        )
        return {(row.schedule_id, row.scheduled_on): row for row in rows}
