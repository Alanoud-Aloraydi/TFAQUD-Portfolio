"""Reading a circle's plans, their versions and the people behind them."""

from sqlalchemy import select

from app.accounts import accounts_by_id
from app.models import MeasurementPlan, MeasurementPlanVersion


class PlanReads:
    """Reads plans and versions."""

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
