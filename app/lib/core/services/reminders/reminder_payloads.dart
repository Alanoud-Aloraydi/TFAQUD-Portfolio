/// The payloads of the reminders set on the phone: which kind of task a
/// notification is about, its circle, the words a snoozable one carries,
/// and the keys of the tasks put off with «ذكّرني لاحقًا». Read by both
/// modes when a reminder is tapped, and by [DoseReminders] when it sets or
/// puts off a reminder.
library;

export 'package:app/core/services/reminders/reminder_payload_parts.dart';
export 'package:app/core/services/reminders/snooze_keys.dart';
export 'package:app/core/services/reminders/snoozed_task.dart';

/// What a dose reminder's payload starts with; the circle's id follows.
const String doseReminderPayload = 'dose:';

/// What a measurement reminder's payload starts with; the circle's id
/// follows.
const String measurementReminderPayload = 'measurement:';

/// What an appointment reminder's payload starts with; the circle's id
/// follows.
const String appointmentReminderPayload = 'appointment:';

/// The payload of the note after the last reminder.
const String keepRemindersPayload = 'reminders:keep';

/// Whether a scheduled notification is one of the reminders.
bool isReminderPayload(String payload) =>
    payload.startsWith(doseReminderPayload) ||
    payload.startsWith(measurementReminderPayload) ||
    payload.startsWith(appointmentReminderPayload) ||
    payload == keepRemindersPayload;

/// What a dose's «ذكّرني لاحقًا» reminder's payload starts with; the
/// circle's id follows, the same as [doseReminderPayload]. A separate
/// prefix and id so [DoseReminders]'s own replace cycle never cancels it
/// as an orphaned reminder.
const String doseSnoozePayload = 'dose-snooze:';

/// The same for a measurement's "ذكّرني لاحقًا".
const String measurementSnoozePayload = 'measurement-snooze:';
