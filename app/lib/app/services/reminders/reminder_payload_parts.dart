import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/features/measurements/domain/entities/measurement_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';

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

/// The circle a tapped reminder is about, or null for the note and for
/// notifications that are not reminders.
String? reminderCircleId(String payload) {
  // Not the circle's id: a snooze action's prefix, the words, a visit's id.
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
      return plain.substring(prefix.length).split(appointmentIdMark).first;
    }
  }
  return null;
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
