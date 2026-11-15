"""One plan as the API answers it."""

from app.accounts import accounts_by_id, recorder_response
from app.clock import patient_today
from app.medications.representations import plan_response, schedule_responses


class PlanResponse:
    """Writes a plan for the API."""

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
