"""HTTP endpoints of the signed-in account: /api/v1/accounts/me.

Flow: the app's ProfileRemoteDataSource -> PUT /me/profile (save_profile)
-> UserStore.update_profile -> the ``account`` table.

Each endpoint lives in its own file and joins the blueprint when imported
here."""

from app.users import account_routes, profile_routes
from app.users.blueprint import bp

__all__ = ["account_routes", "bp", "profile_routes"]
