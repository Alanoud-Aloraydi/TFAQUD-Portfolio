import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_extras.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_status.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a schedule row says beside its mark: the name, the time and kind,
/// how to take it, who comes along, and where it stands.
class SimplifiedScheduleTaskText extends StatelessWidget {
  const SimplifiedScheduleTaskText({
    super.key,
    required this.task,
    required this.day,
    required this.now,
    required this.snoozed,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// The patient's moment, for how long a task has been late.
  final DateTime now;

  /// «سأذكّرك 2:09 مساءً» in place of the status while the task is put off.
  final String? snoozed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          simplifiedTaskTitle(context, task),
          style: SimplifiedStyle.head(SimplifiedStyle.body),
        ),
        Text(
          simplifiedScheduleWhen(context, task),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            weight: AppTextTheme.medium,
          ),
        ),
        SimplifiedScheduleTaskExtras(task: task, day: day),
        SimplifiedScheduleTaskStatus(
          task: task,
          day: day,
          now: now,
          snoozed: snoozed,
        ),
      ],
    );
  }
}

/// What the delete sheet holds: the question, what deleting means, and the
/// two big answers.
Widget simplifiedDeleteSheetBody(BuildContext context) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: <Widget>[
    MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('simplified_mode.delete_title'),
            style: SimplifiedStyle.head(26),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('simplified_mode.delete_text'),
            style: SimplifiedStyle.text(
              SimplifiedStyle.body,
              weight: AppTextTheme.medium,
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    SimplifiedButton(
      label: context.tr('simplified_mode.delete_yes'),
      tone: SimplifiedButtonTone.danger,
      onPressed: () => Navigator.of(context).pop(true),
    ),
    const SizedBox(height: 12),
    SimplifiedButton(
      label: context.tr('simplified_mode.delete_no'),
      tone: SimplifiedButtonTone.quiet,
      onPressed: () => Navigator.of(context).pop(false),
    ),
  ],
);
