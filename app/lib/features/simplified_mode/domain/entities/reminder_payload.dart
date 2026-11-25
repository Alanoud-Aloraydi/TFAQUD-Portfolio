import 'package:app/core/reminders/item_keys.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:equatable/equatable.dart';

/// What a full-screen reminder asks about: the [kind] of task and that
/// exact task by its key (core/reminders/item_keys.dart): a dose's or a measurement's
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
