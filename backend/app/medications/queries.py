"""Read models for medication plans and calculated occurrences."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session
from zoneinfo import ZoneInfo

from app.accounts import accounts_by_id, recorder_response
from app.errors import NotFound
from app.medications.occurrence_builder import build_occurrences
from app.medications.representations import plan_response
from app.medications.representations import schedule_responses
from app.medications.schedule_days import load_days
from app.models import MedicationDoseRecord, MedicationPlan
from app.models import MedicationPlanVersion, MedicationSchedule
from app.models import Patient

RIYADH = ZoneInfo("Asia/Riyadh")


class MedicationQueries:
    """Read plans and derive scheduled occurrences without storing them."""

    def __init__(self, session: Session, now: datetime):
        self.session = session
        self.now = now

    def plans(self, circle_id: UUID) -> list[dict]:
        patient = self._patient(circle_id)
        rows = self.session.execute(
            select(MedicationPlan, MedicationPlanVersion)
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .where(
                MedicationPlan.patient_id == patient.id,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        )
        grouped = {}
        for plan, version in rows:
            grouped.setdefault(plan.id, (plan, []))[1].append(version)
        result = [
            self._plan_response(plan, versions)
            for plan, versions in grouped.values()
        ]
        last_records = self._latest_records(patient.id)
        for item in result:
            item["last_record"] = last_records.get(item["id"])
        return sorted(
            result,
            key=lambda item: (
                item["discontinued_at"] is not None,
                item["version"]["name"],
                item["id"],
            ),
        )

    def _latest_records(self, patient_id: UUID) -> dict[str, dict]:
        """Find the latest explicit dose outcome for each medication plan."""
        ranked = (
            select(
                MedicationPlan.id.label("plan_id"),
                MedicationDoseRecord.outcome,
                MedicationDoseRecord.scheduled_on,
                MedicationDoseRecord.taken_at,
                MedicationDoseRecord.recorded_by_account_id,
                MedicationSchedule.time_of_day,
                func.row_number().over(
                    partition_by=MedicationPlan.id,
                    order_by=(
                        MedicationDoseRecord.scheduled_on.desc(),
                        MedicationSchedule.time_of_day.desc(),
                        MedicationDoseRecord.recorded_at.desc(),
                    ),
                ).label("position"),
            )
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .join(
                MedicationSchedule,
                MedicationSchedule.plan_version_id
                == MedicationPlanVersion.id,
            )
            .join(
                MedicationDoseRecord,
                MedicationDoseRecord.schedule_id
                == MedicationSchedule.id,
            )
            .where(MedicationPlan.patient_id == patient_id)
            .subquery()
        )
        rows = list(self.session.execute(
            select(ranked).where(ranked.c.position == 1)
        ))
        accounts = accounts_by_id(
            self.session,
            {
                row.recorded_by_account_id
                for row in rows
                if row.recorded_by_account_id is not None
            },
        )
        latest = {}
        for row in rows:
            latest[str(row.plan_id)] = {
                "outcome": row.outcome,
                "scheduled_on": row.scheduled_on.isoformat(),
                "time_of_day": row.time_of_day.isoformat(
                    timespec="minutes"
                ),
                "taken_at": (
                    row.taken_at.isoformat() if row.taken_at else None
                ),
                "recorded_by": recorder_response(
                    accounts.get(row.recorded_by_account_id)
                ),
            }
        return latest

    def plan(self, circle_id: UUID, plan_id: UUID) -> dict:
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
                MedicationPlan.patient_id == patient.id,
                MedicationPlanVersion.cancelled_at.is_(None),
            )
        ).all()
        if not rows:
            raise NotFound("The medication plan does not exist.")
        return self._plan_response(rows[0][0], [row[1] for row in rows])

    def _plan_response(self, plan, versions) -> dict:
        """Show the active, pending, and completed versions separately."""
        today = self.now.astimezone(RIYADH).date()
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

    def occurrences(
        self,
        circle_id: UUID,
        from_date: date,
        to_date: date,
        plan_id: UUID | None = None,
    ) -> list[dict]:
        patient = self._patient(circle_id)
        statement = (
            select(
                MedicationPlan,
                MedicationPlanVersion,
                MedicationSchedule,
            )
            .join(
                MedicationPlanVersion,
                MedicationPlanVersion.medication_plan_id
                == MedicationPlan.id,
            )
            .join(
                MedicationSchedule,
                MedicationSchedule.plan_version_id
                == MedicationPlanVersion.id,
            )
            .where(
                MedicationPlan.patient_id == patient.id,
                MedicationPlanVersion.treatment_starts_on <= to_date,
                MedicationPlanVersion.cancelled_at.is_(None),
                (
                    MedicationPlanVersion.treatment_ends_on.is_(None)
                    | (
                        MedicationPlanVersion.treatment_ends_on
                        >= from_date
                    )
                ),
            )
        )
        if plan_id is not None:
            statement = statement.where(MedicationPlan.id == plan_id)
        rows = list(self.session.execute(statement))
        schedule_ids = {row[2].id for row in rows}
        days = load_days(self.session, [row[2] for row in rows])
        records = self._records(schedule_ids, from_date, to_date)
        accounts = accounts_by_id(
            self.session,
            {
                record.recorded_by_account_id
                for record in records.values()
                if record.recorded_by_account_id is not None
            },
        )
        return build_occurrences(
            rows, days, records, accounts, from_date, to_date, self.now
        )

    def _patient(self, circle_id: UUID) -> Patient:
        patient = self.session.scalar(
            select(Patient).where(Patient.care_circle_id == circle_id)
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
