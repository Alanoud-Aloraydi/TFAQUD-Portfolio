import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';

/// Which kind of task a tapped reminder (or snooze) is about, so the
/// simplified mode opens its full-screen reminder; null for the note to
/// open the app and for anything that is not a reminder.
TodayTaskKind? reminderTaskKind(String payload) {
  if (reminderCircleId(payload) == null) return null;
  if (payload.startsWith(doseReminderPayload) ||
      payload.startsWith(doseSnoozePayload)) {
    return TodayTaskKind.medication;
  }
  if (payload.startsWith(measurementReminderPayload) ||
      payload.startsWith(measurementSnoozePayload)) {
    return TodayTaskKind.measurement;
  }
  if (payload.startsWith(appointmentReminderPayload)) {
    return TodayTaskKind.appointment;
  }
  return null;
}
