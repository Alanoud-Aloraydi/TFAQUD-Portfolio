import 'package:app/core/reminders/reminder_payloads.dart';
import 'package:equatable/equatable.dart';

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

/// A dose or measurement put off with «ذكّرني لاحقًا»: its circle, which
/// kind of task, its [subject] (the medicine's name, or the measurement
/// kind's name) and the moment [at] it is reminded of again. The cards of
/// both modes show the time; the calendar copy moves to it.
class TaskSnooze extends Equatable {
  const TaskSnooze({
    required this.circleId,
    required this.task,
    required this.subject,
    required this.at,
  });

  final String circleId;
  final SnoozedTask task;
  final String subject;

  /// In UTC.
  final DateTime at;

  @override
  List<Object?> get props => [circleId, task, subject, at];
}

/// A task put off, and the slot of its reminder.
typedef SnoozeSlot = ({TaskSnooze snooze, int slot});
