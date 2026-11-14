"""The bell's «السابقة»: what was answered in the last 30 days."""

from flask import Blueprint

from app.auth.decorators import require_auth
from app.circles import views
from app.circles.support import answer, care_work
from app.errors import NotFound
from app.models import Account

bp = Blueprint(
    "previous_notifications", __name__, url_prefix="/api/v1/notifications"
)


@bp.get("/previous")
@require_auth
def previous():
    """Invitations and circle requests to and from the caller that were
    answered in the last 30 days, newest first."""
    with care_work() as work:
        account = work.session.get(Account, work.actor)
        if account is None:
            raise NotFound("This user does not exist.", code="user_not_found")
        items = views.previous_notifications_view(
            work.session, account, work.now
        )
    return answer({"previous": items})
