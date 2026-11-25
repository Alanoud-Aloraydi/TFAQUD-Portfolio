import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/push_target.dart';
import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/app/services/reminders/tapped_item.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:equatable/equatable.dart';

/// What a full-screen reminder asks about: the [kind] of task and that
/// exact task by its key (item_keys.dart): a dose's or a measurement's
/// [TodayTaskSnoozeKey.snoozeKey], a visit's [appointmentItemKey].
///
/// A null [taskKey] (an older reminder that names no task) means the task
/// of [kind] waiting now: for an appointment, the nearest one still to
/// come; for a dose or a measurement, the one of that kind due now.
class ReminderRequest extends Equatable {
  const ReminderRequest(this.kind, {this.taskKey});

  /// The reminder of [task], a task the patient opened in [circleId].
  ReminderRequest.of(TodayTask task, String circleId)
    : this(
        task.kind,
        taskKey:
            task.snoozeKey(circleId) ??
            appointmentItemKey(circleId, task.appointment!.id),
      );

  final TodayTaskKind kind;

  /// The task's key; null when the reminder names none.
  final String? taskKey;

  @override
  List<Object?> get props => [kind, taskKey];
}

/// What a tapped reminder (or snooze) asks about, so the simplified mode
/// opens its full-screen reminder; null for the note to open the app and
/// for anything that is not a reminder. A server push about a dose or a
/// reading put off or missed, or a visit missed, opens that task the same
/// way.
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
  return ReminderRequest(kind, taskKey: tappedItemKey(payload));
}

/// A missed visit opens its reminder too: «حضرت» can still be said.
ReminderRequest? _pushRequest(String kind, String? item) => switch (kind) {
  'dose_missed' ||
  'dose_snoozed' => ReminderRequest(TodayTaskKind.medication, taskKey: item),
  'measurement_missed' || 'measurement_snoozed' => ReminderRequest(
    TodayTaskKind.measurement,
    taskKey: item,
  ),
  'appointment_missed' => ReminderRequest(
    TodayTaskKind.appointment,
    taskKey: item,
  ),
  _ => null,
};

/// The visit a reminder for [request] asks about, while it is still open
/// (scheduled): that exact one of [day] by its key, on any day, or,
/// without a key, the nearest still to come. Null once it was attended or
/// cancelled: someone in the family may have said so first.
CareAppointment? reminderAppointment(
  ReminderRequest request,
  SimplifiedDay day,
  TodaySchedule schedule,
) {
  final String? key = request.taskKey;
  if (key == null) return schedule.upcomingAppointment;
  for (final CareAppointment item in day.appointments) {
    if (item.status == AppointmentStatus.scheduled &&
        appointmentItemKey(day.circleId, item.id) == key) {
      return item;
    }
  }
  return null;
}
