"""The reminders at a task's time, sent by the server.

A reminder comes at each dose and reading time not recorded yet, and a day
before an appointment and at the lead chosen for it (and once right after
a visit saved too late for the one a day before). The phone used to set
them itself, from the plan as it read it when the app was last opened: a
plan someone else changed meanwhile went on reminding of the old one. The
server reads the plan at each reminder's moment instead, so it reminds of
the plan as it is then, the people in the circle then. Nothing is booked
ahead anywhere, so nothing old is ever sent.

The words, the people and the moments are the app's own
(lib/core/services/reminders), so a reminder reads the same from either,
and a tap on it, or «ذكّرني لاحقًا», does the same. They go only to the
phones whose app asked for them with its push subscription
(`server_reminders` on its sign-in, app/push/routes.py); an app from
before goes on setting its own, so nobody is reminded twice.

The minute scan (app/minute_scan.py) sends what came due and sets a timer
for each moment before its next pass, so a reminder comes on its minute.
Each is claimed once in `notification_log`, so the processes, the timers
and the cron's scan never send one twice. One the server could not send
within `LATE_AT_MOST` of its time (it was away) is not sent: the push of
the missed task follows.

SERVER_REMINDERS=false stops them all; each app sets its own again the
next time it opens.
"""

from app.push.scheduled.reminders.scan import (
    LATE_AT_MOST,
    remind_on_time,
    scan_reminders,
)
from app.push.scheduled.reminders.switch import listening, reminders_on

__all__ = [
    "LATE_AT_MOST",
    "listening",
    "remind_on_time",
    "reminders_on",
    "scan_reminders",
]
