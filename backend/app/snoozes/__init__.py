"""«ذكّرني لاحقًا», shared by the circle.

Any member can put off a dose or a reading time for some minutes
(`PUT /api/v1/circles/<id>/task-snoozes`). The server keeps it, so:

  - every member's card shows who put it off and until when (each
    occurrence of /medication-occurrences and /measurement-occurrences
    carries its `snooze`);
  - when that time comes, every member is reminded by a push, except the
    one who put it off: their own phone reminds them by itself (due.py);
  - the missed-task scan waits while a task is put off (push/scheduled.py).
"""
