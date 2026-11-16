"""The services every request reaches through `app.extensions`: the clock,
the SMS and push senders, circle access, sessions, users and sign-in."""

from contextlib import nullcontext
from datetime import timedelta

from flask import Flask

from app.auth.service import SessionService
from app.auth.sign_in import SignInService
from app.database import transaction
from app.factory.stores import Stores


def register_services(
    app: Flask, stores: Stores, *, clock, sms_sender, push_sender,
    database: bool,
) -> None:
    """Make the session and sign-in services and keep every service in
    `app.extensions`."""
    config = app.config
    session_service = SessionService(
        store=stores.session,
        secret_key=config["SECRET_KEY"],
        access_ttl=timedelta(minutes=config["ACCESS_TOKEN_MINUTES"]),
        clock=clock,
    )
    app.extensions.update({
        "clock": clock,
        "sms_sender": sms_sender,
        # Push notifications to signed-in phones; "none" unless set up.
        "push_sender": push_sender,
        "circle_access": stores.circle_access,
        "session_service": session_service,
        "user_store": stores.user,
        "sign_in_service": SignInService(
            otp_store=stores.otp,
            user_store=stores.user,
            sms_sender=sms_sender,
            session_service=session_service,
            clock=clock,
            otp_valid_seconds=config["OTP_VALID_SECONDS"],
            max_wrong_tries=config["OTP_MAX_WRONG_TRIES"],
            max_sends_per_day=config["OTP_MAX_SENDS_PER_DAY"],
            resend_waits=config["OTP_RESEND_WAITS"],
            max_sends_per_device_hour=config[
                "OTP_MAX_SENDS_PER_DEVICE_HOUR"
            ],
            max_sends_per_ip_hour=config["OTP_MAX_SENDS_PER_IP_HOUR"],
            transaction=transaction if database else nullcontext,
        ),
    })
