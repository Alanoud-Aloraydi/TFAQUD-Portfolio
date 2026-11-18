import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What the late dose card says, in its order, its three answers last.
List<String> simplifiedLateDoseLines(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  String? snoozed,
) => <String>[
  context.tr('simplified_mode.late_question'),
  task.dose!.name,
  simplifiedDoseAmount(context, task.dose!),
  ...simplifiedTaskChips(context, task, day),
  simplifiedLateDoseWasDue(context, task),
  ?snoozed,
  context.tr('simplified_mode.took_now'),
  context.tr('simplified_mode.remind_later'),
  context.tr('simplified_mode.not_taken'),
];

/// «كان موعده 6:00 مساءً».
String simplifiedLateDoseWasDue(BuildContext context, TodayTask task) =>
    context.tr(
      'simplified_mode.was_due',
      args: <String>[simplifiedTime(context, task.time)],
    );

/// What the card says without its three answers: the buttons name
/// themselves, and stay their own stops for a screen reader.
String simplifiedLateDoseSaid(
  BuildContext context,
  TodayTask task,
  SimplifiedDay day,
  String? snoozed,
) {
  final List<String> said = simplifiedLateDoseLines(
    context,
    task,
    day,
    snoozed,
  );
  return said.sublist(0, said.length - 3).join('، ');
}
