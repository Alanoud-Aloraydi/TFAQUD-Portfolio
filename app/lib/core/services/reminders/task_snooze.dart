import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:equatable/equatable.dart';

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
