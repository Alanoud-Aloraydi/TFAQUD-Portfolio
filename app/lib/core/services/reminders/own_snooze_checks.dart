import 'package:app/core/services/reminder_circle.dart';
import 'package:app/core/services/reminders/shared_snooze.dart';
import 'package:app/core/services/reminders/snoozed_task.dart';
import 'package:app/core/services/reminders/task_snooze.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';

/// Not recorded yet: a reading done or skipped is reminded of no more.
bool measurementOpen(MeasurementOccurrence task) =>
    task.record == null &&
    task.status != MeasurementStatus.read &&
    task.status != MeasurementStatus.skipped;

/// Put off by the person on this phone, and still waiting.
bool ownWaitingSnooze(
  ReminderCircle circle,
  SharedSnooze? shared,
  DateTime now,
) =>
    shared != null &&
    circle.viewerId != null &&
    shared.byAccountId == circle.viewerId &&
    shared.waitsAt(now);

/// The snooze this phone keeps for a task the server has put off.
TaskSnooze taskSnoozeOf(
  ReminderCircle circle,
  SnoozedTask task,
  String subject,
  SharedSnooze shared,
) => TaskSnooze(
  circleId: circle.id,
  task: task,
  subject: subject,
  at: shared.remindAt.toUtc(),
);
