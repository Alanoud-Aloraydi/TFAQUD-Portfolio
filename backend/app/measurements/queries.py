"""Measurement reads, only ever of the selected circle's patient: the
plans with their versions and the people behind them, the tasks, and the
readings."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.accounts import accounts_by_id, recorder_response
from app.clock import patient_today
from app.measurements.plans import circle_for, plan_times, plan_weekdays
from app.measurements.reading_queries import Readings
from app.measurements.responses import version_response
from app.measurements.task_queries import Tasks
from app.models import MeasurementPlan, MeasurementPlanVersion


class MeasurementQueries(Tasks, Readings):
    """Read only data belonging to the selected circle's patient."""

    def __init__(self, session: Session, now: datetime):
        """Read inside the caller's session, at the time `now`."""
        self.session = session
        self.now = now

    # Lists plans.
    def plans(self, circle_id: UUID) -> list[dict]:
        """Return active and stopped plans with version history."""
        circle = circle_for(self.session, circle_id)
        plans = self._circle_plans(circle)
        if not plans:
            return []
        versions = self._plan_versions(plans)
        people = self._plan_people(plans, versions)
        by_plan: dict[UUID, list[MeasurementPlanVersion]] = {}
        for version in versions:
            by_plan.setdefault(version.measurement_plan_id, []).append(version)
        ids = [version.id for version in versions]
        times = plan_times(self.session, ids)
        weekdays = plan_weekdays(self.session, ids)
        today = patient_today(circle, self.now)

        def shown(version):
            return version_response(
                version, times[version.id], weekdays[version.id]
            )

        return [
            self._plan_item(plan, by_plan[plan.id], today, people, shown)
            for plan in plans
        ]

    @staticmethod
    def _plan_item(plan, history, today, people, shown) -> dict:
        """One plan with the version in effect today, the one coming, and
        its history."""
        current = next(
            (
                version
                for version in reversed(history)
                if version.effective_from_on <= today
            ),
            history[0],
        )
        pending = next(
            (
                version
                for version in history
                if version.effective_from_on > today
                and version.id != current.id
            ),
            None,
        )
        return {
            "id": str(plan.id),
            "kind": plan.kind,
            "created_at": plan.created_at.isoformat(),
            "created_by": recorder_response(
                people.get(plan.created_by_account_id)
            ),
            # Who made the version in effect now — the same person as
            # created_by unless the plan was revised since.
            "last_edited_by": recorder_response(
                people.get(current.created_by_account_id)
            ),
            "stopped_at": (
                plan.stopped_at.isoformat() if plan.stopped_at else None
            ),
            "stopped_by": recorder_response(
                people.get(plan.stopped_by_account_id)
            ),
            "version": shown(current),
            "pending_version": shown(pending) if pending else None,
            "history": [shown(item) for item in history],
        }

    # Reads plans and versions.
    def _circle_plans(self, circle) -> list:
        """The circle's plans, newest first."""
        return list(
            self.session.scalars(
                select(MeasurementPlan)
                .where(MeasurementPlan.care_circle_id == circle.id)
                .order_by(MeasurementPlan.created_at.desc())
            )
        )

    def _plan_versions(self, plans) -> list:
        """Every version of `plans`, in order."""
        return list(
            self.session.scalars(
                select(MeasurementPlanVersion)
                .where(
                    MeasurementPlanVersion.measurement_plan_id.in_(
                        [plan.id for plan in plans]
                    )
                )
                .order_by(MeasurementPlanVersion.version_number)
            )
        )

    def _plan_people(self, plans, versions) -> dict:
        """Who made, stopped and edited the plans, read at once."""
        return accounts_by_id(
            self.session,
            {
                account_id
                for plan in plans
                for account_id in (
                    plan.created_by_account_id, plan.stopped_by_account_id
                )
                if account_id is not None
            }
            | {
                version.created_by_account_id
                for version in versions
                if version.created_by_account_id is not None
            },
        )
