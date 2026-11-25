import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/medicine_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// The medicine of the late dose card: its photo, its name and what to
/// take.
class SimplifiedLateDoseMedicine extends StatelessWidget {
  const SimplifiedLateDoseMedicine({
    super.key,
    required this.task,
    required this.day,
  });

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        MedicinePhoto(
          circleId: day.circleId,
          planId: task.dose!.planId,
          height: 124,
          width: 124,
          radius: 30,
          iconSize: 48,
        ),
        const SizedBox(height: 12),
        Text(
          task.dose!.name,
          textAlign: TextAlign.center,
          style: SimplifiedStyle.head(SimplifiedStyle.name),
        ),
        Text(
          simplifiedDoseAmount(context, task.dose!),
          style: SimplifiedStyle.head(SimplifiedStyle.headline),
        ),
        if (simplifiedDoseReason(task, day) == null)
          Text(
            simplifiedStrength(context, task.dose!),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
      ],
    );
  }
}

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
