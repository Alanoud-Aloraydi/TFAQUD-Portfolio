"""The scheduled tick: the reminders at a task's time, and a dose, a
measurement or an appointment that was missed, each told once to the circle
and logged so a repeat tick never resends it. Each person is called by name
(app/push/missed_texts.py).

The reminders at a dose's, a reading's or an appointment's time (and for an
appointment a day before and at the lead chosen for it) go to the phones
whose app leaves them to the server (reminders/); an app from before sets
them on its phone itself. The server also tells what no phone can know
ahead: that a task's time passed and nothing was recorded, that an
appointment passed two hours ago and nobody marked it visited or cancelled,
and that a task someone else put off came again (app/snoozes/due.py; this
tick catches what its timer missed). A task put off is not called missed
while it waits.

Called by `/internal/tick` on an external schedule (see README). Never
raises: a failed scan or send is logged and the tick moves on, so one bad
circle never blocks the rest. Each tick also deletes the rows kept only for
a while: sign-in code requests after 30 days (they hold a phone number,
a device id and an IP address), and its own log after 14 days."""

from app.push.scheduled.purge import purge_old_rows
from app.push.scheduled.tick import run_tick

__all__ = [
    "purge_old_rows",
    "run_tick",
]
