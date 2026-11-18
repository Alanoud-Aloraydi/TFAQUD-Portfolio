import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
