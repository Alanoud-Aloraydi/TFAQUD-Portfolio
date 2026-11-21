"""The privacy policy, the terms, and how to delete an account: plain
pages for anyone, with no sign-in. The App Store and Google Play link to
them, and the app opens the first two from «حسابي» and the welcome."""

from flask import Blueprint, current_app, render_template

bp = Blueprint("legal", __name__, template_folder="templates")

# The day the texts last changed, shown at the top of each page.
UPDATED = "20 نوفمبر 2026"


def _page(name: str) -> str:
    return render_template(
        f"legal/{name}.html",
        updated=UPDATED,
        email=current_app.config.get("LEGAL_CONTACT_EMAIL"),
    )


@bp.get("/privacy")
def privacy():
    return _page("privacy")


@bp.get("/terms")
def terms():
    return _page("terms")


@bp.get("/delete-account")
def delete_account():
    return _page("delete_account")
