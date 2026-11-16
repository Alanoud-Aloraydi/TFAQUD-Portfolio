import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/domain/reminder_appointment.dart';
import 'package:app/features/simplified_mode/domain/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/today_schedule.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_appointment_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_dose_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_measurement_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_content.dart';
import 'package:flutter/widgets.dart';

/// What the reminder for [request] shows on [state]'s day: a dose's, a
/// reading's or a visit's. Null while the day is not read, and once its
/// task no longer waits (someone in the family may have recorded it).
SimplifiedReminderContent? reminderContent(
  BuildContext context,
  ReminderRequest request,
  SimplifiedModeState state,
) {
  final SimplifiedDay? day = state.day;
  final TodaySchedule? schedule = state.schedule;
  if (day == null || schedule == null) return null;
  final TodayTask? task = schedule.reminderTask(request, day.circleId);
  return switch (request.kind) {
    TodayTaskKind.medication => reminderDoseContent(
      context,
      task,
      day,
      saving: state.saving,
    ),
    TodayTaskKind.measurement => reminderMeasurementContent(context, task, day),
    TodayTaskKind.appointment => reminderAppointmentContent(
      context,
      reminderAppointment(request, day, schedule),
      day.circleId,
      now: state.now,
      saving: state.saving,
    ),
  };
}
