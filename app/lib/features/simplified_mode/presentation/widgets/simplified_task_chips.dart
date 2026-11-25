import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// What a dose's medicine is for («الكوليسترول»), when the plan says. It
/// is said once, as a chip, never again beside the amount.
String? simplifiedDoseReason(TodayTask task, SimplifiedDay day) =>
    day.reasons[task.dose!.planId] ?? task.dose!.reason;

/// The notes drawn as plain labels: every one of [simplifiedTaskChips]
/// but a visit's companions, who are drawn with their photos before their
/// names (SimplifiedCompanions).
List<String> simplifiedTaskNotes(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
) => task.kind == TodayTaskKind.appointment
    ? const <String>[]
    : simplifiedTaskChips(context, task, day);

/// The short notes of a task, as words: a dose's instructions and the
/// medicine's reason, a glucose task's context, an appointment's
/// companions («معك: لينا»).
List<String> simplifiedTaskChips(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
) {
  return switch (task.kind) {
    TodayTaskKind.medication => <String>[
      if (task.dose!.instructions case final String text
          when text.trim().isNotEmpty)
        text.trim(),
      ?simplifiedDoseReason(task, day),
    ],
    TodayTaskKind.measurement => <String>[
      if (task.measurement!.measurementState case final state?)
        context.tr('measurements.condition.$state'),
    ],
    TodayTaskKind.appointment => <String>[
      if (task.appointment!.companions.isNotEmpty)
        context.tr(
          'simplified_mode.with_companions',
          args: <String>[
            task.appointment!.companions
                .map((companion) => companion.name)
                .join(context.tr('appointments.companion_separator')),
          ],
        ),
    ],
  };
}

/// What a schedule row says: the name, the time and kind, how to take it,
/// and where it stands.
List<String> simplifiedScheduleLines(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  DateTime now,
  String? snoozed,
) => <String>[
  simplifiedTaskTitle(context, task),
  simplifiedScheduleWhen(context, task),
  ?simplifiedScheduleHow(context, task, day, companions: true),
  snoozed ?? simplifiedTaskStatus(context, task, day, now),
];

/// How it is taken: «حبة واحدة، مع الأكل», the same words the cards
/// show, so the schedule says enough to act on without opening a task.
/// With [companions] it names who comes along to a visit, for the
/// spoken row; on the row itself they are drawn with their photos.
String? simplifiedScheduleHow(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day, {
  required bool companions,
}) {
  final List<String> parts = <String>[
    if (task.kind == TodayTaskKind.medication)
      simplifiedDoseAmount(context, task.dose!),
    ...(companions ? simplifiedTaskChips : simplifiedTaskNotes)(
      context,
      task,
      day,
    ),
  ];
  return parts.isEmpty ? null : parts.join('، ');
}

/// «6:00 مساءً، دواء».
String simplifiedScheduleWhen(BuildContext context, TodayTask task) =>
    '${simplifiedTime(context, task.time)}، '
    '${context.tr('simplified_mode.kind.${task.kind.name}')}';
