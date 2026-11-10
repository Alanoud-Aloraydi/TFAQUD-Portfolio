/// The payloads of the reminders set on the phone: which kind of task a
/// notification is about, its circle, the words a snoozable one carries,
/// and the keys of the tasks put off with «ذكّرني لاحقًا». Read by both
/// modes when a reminder is tapped, and by [DoseReminders] when it sets or
/// puts off a reminder.
library;

import 'package:app/core/services/phone_notifications.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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

/// Between a payload's circle and the words a snoozable reminder carries,
/// so «ذكّرني لاحقًا» in the notification can show them again.
const String _textSeparator = '\u001F';

/// [payload] with [title] and [body] after it, and, for a dose or a
/// measurement, its [snoozeKey] and [subject] ([TaskSnooze.subject]), so
/// «ذكّرني لاحقًا» in the notification puts off that same task.
String payloadWithText(
  String payload,
  String title,
  String body, {
  String? snoozeKey,
  String? subject,
}) => <String>[
  payload,
  title,
  body,
  if (snoozeKey != null && subject != null) ...<String>[snoozeKey, subject],
].join(_textSeparator);

/// The title and body a reminder's payload carries, or null.
(String, String)? reminderText(String payload) {
  final List<String> parts = payload.split(_textSeparator);
  return parts.length >= 3 ? (parts[1], parts[2]) : null;
}

/// The task's key ([doseSnoozeKey], [measurementSnoozeKey]) and subject a
/// reminder's payload carries, or null.
(String, String)? snoozeTarget(String payload) {
  final List<String> parts = payload.split(_textSeparator);
  return parts.length == 5 ? (parts[3], parts[4]) : null;
}

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

/// What a snooze reminds of again.
enum SnoozedTask {
  dose(doseSnoozePayload),
  measurement(measurementSnoozePayload);

  const SnoozedTask(this.payloadPrefix);

  final String payloadPrefix;

  /// What a reminder or snooze [payload] is about: a measurement's stays a
  /// measurement when put off again, anything else is a dose.
  static SnoozedTask of(String payload) =>
      payload.startsWith(measurementReminderPayload) ||
          payload.startsWith(measurementSnoozePayload)
      ? SnoozedTask.measurement
      : SnoozedTask.dose;
}

/// A dose put off: its circle, its time of the plan, and its day.
String doseSnoozeKey(String circleId, DoseOccurrence dose) {
  final DateTime day = dose.scheduledOn;
  return '$circleId|${dose.scheduleId}|${day.year}-${day.month}-${day.day}';
}

/// A measurement put off: its circle, its plan's version, its time and its
/// day.
String measurementSnoozeKey(String circleId, MeasurementOccurrence task) {
  final DateTime day = task.scheduledOn;
  return '$circleId|measurement|${task.versionId}|${task.time}|'
      '${day.year}-${day.month}-${day.day}';
}

/// The circle a tapped reminder is about, or null for the note and for
/// notifications that are not reminders.
String? reminderCircleId(String payload) {
  // A snooze action's tap, and the words after the circle, are not part of
  // the circle's id.
  final String plain =
      (isSnoozeTap(payload)
              ? payload.substring(snoozeTapPrefix.length)
              : payload)
          .split(_textSeparator)
          .first;
  for (final String prefix in <String>[
    doseReminderPayload,
    measurementReminderPayload,
    appointmentReminderPayload,
    doseSnoozePayload,
    measurementSnoozePayload,
  ]) {
    if (plain.startsWith(prefix) && plain.length > prefix.length) {
      return plain.substring(prefix.length);
    }
  }
  return null;
}
