import 'package:app/core/services/reminders/item_keys.dart';
import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';

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
