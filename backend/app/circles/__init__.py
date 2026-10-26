"""Endpoints for care circles, creation requests, invitations and the
medical file. The rules live in `app.care` and `app.medical`; this package
only reads the request, calls them inside one transaction, and shapes the
answer.
"""
