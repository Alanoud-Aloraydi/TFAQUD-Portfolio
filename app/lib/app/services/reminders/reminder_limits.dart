/// iOS keeps at most 64 scheduled notifications for an app (the 64 set
/// last). The reminders of doses, measurements and appointments share
/// [maxDoseReminders] of them, the nearest first; the note after them takes
/// one more. A dose or measurement put off takes the place of one of the
/// reminders (`maxCardSnoozes`).
const int maxDoseReminders = 60;

/// The ids of the reminders: [reminderIdBase] to [reminderIdBase] + 60.
const int reminderIdBase = 7000;

/// A reminder this close is not set: by the time the phone has it, its
/// moment may have passed. Short, so a medicine saved a minute before its
/// dose is still reminded.
const Duration reminderMargin = Duration(seconds: 10);

/// How long after an appointment is saved its «اليوم» reminder comes, when
/// it was saved after its day-before moment: right away, with time for the
/// phone to set it.
const Duration appointmentSavedLead = Duration(seconds: 30);

/// How many days are read ahead. A week is enough while the app is opened
/// now and then, and stays well under the 31 days the server gives at once.
const int reminderDays = 7;

/// The slots of the tasks put off («ذكّرني لاحقًا», in either mode), after
/// the note's: each has its own, so two tasks put off both come again.
const int cardSnoozeIdBase = reminderIdBase + maxDoseReminders + 1;

/// At most this many tasks put off at once. The reminders to come give up
/// as many places, so the phone's 64 are never passed.
const int maxCardSnoozes = 5;
