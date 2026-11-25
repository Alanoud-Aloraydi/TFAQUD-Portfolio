import 'package:app/app/services/reminders/reminder_payloads.dart';

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
