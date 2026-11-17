"""The scheduled tick: a dose, a measurement or an appointment that was
missed, each told once to the circle and logged so a repeat tick never
resends it. Each person is called by name (app/push/missed_texts.py).

The reminders before a dose, a measurement or an appointment (at its time, and
for an appointment a day before and at the lead chosen for it) are set on each
phone by the app itself, so they come on time without this tick and without
the server. The server tells only what a phone cannot know ahead: that a
task's time passed and nothing was recorded, that an appointment passed two
hours ago and nobody marked it visited or cancelled, and that a task someone
else put off came again (app/snoozes/due.py; this tick catches what its timer
missed). A task put off is not called missed while it waits.

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
