"""What a send can end in."""

SENT = "sent"
# OneSignal knows no phone of the account that can show a push (it never
# signed in on the new app, or it refused notifications).
NO_DEVICE = "no_device"
FAILED = "failed"  # Anything else.
