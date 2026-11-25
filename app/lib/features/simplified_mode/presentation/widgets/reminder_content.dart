import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/simplified_mode_state.dart';
import 'package:app/features/simplified_mode/presentation/widgets/measurement_verdict.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_appointment_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/reminder_dose_content.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_nothing_waiting.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reminder_round_answer.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

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

/// The reminder of a reading: its kind's picture, how to take it, and
/// «تسجيل القياس الآن» or «ذكّرني لاحقًا». Null when [task] no longer
/// waits.
SimplifiedReminderContent? reminderMeasurementContent(
  BuildContext context,
  TodayTask? task,
  SimplifiedDay day,
) {
  if (task == null) return null;
  final MeasurementOccurrence item = task.measurement!;
  final bool bp = item.kind == MeasurementKind.bp;
  return SimplifiedReminderContent(
    lead: context.tr('simplified_mode.time_for'),
    name: simplifiedMeasurementTitle(context, item.kind),
    line: bp
        ? context.tr('simplified_mode.bp_rest')
        : simplifiedTime(context, item.time),
    chips: <String>[
      if (bp) context.tr('simplified_mode.bp_arm'),
      if (item.measurementState case final state?)
        context.tr('measurements.condition.$state'),
    ],
    hero: (double height) => SimplifiedReminderIconHero(
      icon: measurementIcon(item.kind),
      ground: CareVisuals.measurementTile,
      height: height,
    ),
    yesLabel: context.tr('simplified_mode.measure_now'),
    onYes: () => context.pushReplacement(
      Routes.simplifiedMeasure(day.circleId),
      extra: item,
    ),
    onLater: () =>
        unawaited(openSimplifiedSnooze(context, task, replace: true)),
  );
}
