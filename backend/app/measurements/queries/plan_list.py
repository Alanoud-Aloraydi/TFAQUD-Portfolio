"""The plans of a circle, each with its versions."""

from uuid import UUID

from app.accounts import recorder_response
from app.clock import patient_today
from app.measurements.queries.responses import version_response
from app.measurements.service import circle_for, plan_times, plan_weekdays
from app.models import MeasurementPlanVersion


class PlanList:
    """Lists plans."""

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
