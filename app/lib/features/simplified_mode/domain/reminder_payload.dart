import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/push_target.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:equatable/equatable.dart';

/// What a full-screen reminder asks about: the [kind] of task and, for a
/// dose or a measurement, that exact task by its [TodayTask.snoozeKey].
///
/// A null [taskKey] means the task of [kind] waiting now: for an
/// appointment, the nearest one still to come; for a dose or a measurement
/// (a reminder that carries no key), the one of that kind due now.
class ReminderRequest extends Equatable {
  const ReminderRequest(this.kind, {this.taskKey});

  /// The reminder of [task], a task the patient opened in [circleId].
  ReminderRequest.of(TodayTask task, String circleId)
    : this(task.kind, taskKey: task.snoozeKey(circleId));

  final TodayTaskKind kind;

  /// The task's [TodayTask.snoozeKey]; null for an appointment.
  final String? taskKey;

  @override
  List<Object?> get props => [kind, taskKey];
}

/// What a tapped reminder (or snooze) asks about, so the simplified mode
/// opens its full-screen reminder; null for the note to open the app and
/// for anything that is not a reminder. A server push about a dose or a
/// reading put off or missed opens that task the same way.
ReminderRequest? reminderRequest(String payload) {
  if (pushKind(payload) case final String kind) {
    return _pushRequest(kind, pushTapItem(payload));
  }
  if (reminderCircleId(payload) == null) return null;
  final TodayTaskKind? kind =
      payload.startsWith(doseReminderPayload) ||
          payload.startsWith(doseSnoozePayload)
      ? TodayTaskKind.medication
      : payload.startsWith(measurementReminderPayload) ||
            payload.startsWith(measurementSnoozePayload)
      ? TodayTaskKind.measurement
      : payload.startsWith(appointmentReminderPayload)
      ? TodayTaskKind.appointment
      : null;
  if (kind == null) return null;
  return ReminderRequest(kind, taskKey: snoozeTarget(payload)?.$1);
}

/// A missed visit has no reminder to open: its time has passed.
ReminderRequest? _pushRequest(String kind, String? item) => switch (kind) {
  'dose_missed' ||
  'dose_snoozed' => ReminderRequest(TodayTaskKind.medication, taskKey: item),
  'measurement_missed' || 'measurement_snoozed' => ReminderRequest(
    TodayTaskKind.measurement,
    taskKey: item,
  ),
  _ => null,
};
