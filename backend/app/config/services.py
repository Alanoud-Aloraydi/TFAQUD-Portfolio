"""The settings of the services around sign-in: pushes, the demo accounts,
the scheduled scan and work done after the answer."""

import os


def service_settings(env_name: str) -> dict:
    """The push, demo, scan and background part of the settings."""
    return {
        # Push notifications: "none" (nothing is sent) or "onesignal"
        # (iOS and Android, through OneSignal). The app id names the
        # OneSignal app; the App API key is a secret, typed in Render only.
        "PUSH_BACKEND": os.environ.get("PUSH_BACKEND", "none"),
        "ONESIGNAL_APP_ID": os.environ.get("ONESIGNAL_APP_ID"),
        "ONESIGNAL_API_KEY": os.environ.get("ONESIGNAL_API_KEY"),
        # The one code the demo accounts (app/demo_accounts.py) sign in
        # with, six digits, so a shared test server with real SMS can show
        # the demo: those made-up numbers get no SMS. Unset: no demo
        # sign-in. Refused in production.
        "DEMO_SIGN_IN_CODE": (
            os.environ.get("DEMO_SIGN_IN_CODE", "").strip() or None
        ),
        # Shared secret for /internal/tick and /internal/metrics (the
        # scheduled scan runs as `flask --app wsgi tick` on Render's cron).
        # None (unset) keeps the endpoints refusing every request.
        "TICK_SECRET": os.environ.get("TICK_SECRET"),
        # The API's health check, asked by each scheduled scan so the free
        # API never sleeps (app/keep_awake.py). Unset: nothing is asked.
        "KEEP_AWAKE_URL": os.environ.get("KEEP_AWAKE_URL") or None,
        # The same scan inside each API process, every this many seconds
        # (app/minute_scan.py), so a missed task is told within a minute;
        # 0 turns it off. On by default on Render (staging, production).
        "SCAN_EVERY_SECONDS": int(
            os.environ.get("SCAN_EVERY_SECONDS")
            or (60 if env_name in ("staging", "production") else 0)
        ),
        # Push notifications and other work no one waits for run after the
        # answer (app/background.py); tests run them at once.
        "BACKGROUND_INLINE": env_name == "testing",
    }
