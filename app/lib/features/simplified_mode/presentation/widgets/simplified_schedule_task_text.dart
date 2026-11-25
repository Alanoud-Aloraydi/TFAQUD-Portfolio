import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_extras.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_mark.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_status.dart';
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

/// Where a schedule row stands: what was recorded once it is done, else
/// its status or what it was put off to.
class SimplifiedScheduleTaskStatus extends StatelessWidget {
  const SimplifiedScheduleTaskStatus({
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
    final String status =
        snoozed ?? simplifiedTaskStatus(context, task, day, now);
    final TextStyle statusStyle = SimplifiedStyle.head(
      SimplifiedStyle.caption,
      color: SimplifiedTaskMark.ink(task.status),
    );
    if (snoozed == null && task.status == TodayTaskStatus.done) {
      return SimplifiedDoneLine(task: task, day: day, style: statusStyle);
    }
    return SimplifiedSnoozedLine(
      text: status,
      task: task,
      day: day,
      style: statusStyle,
    );
  }
}

/// A done task's last line: «تم 4:30 مساءً»، then the photo of who
/// pressed it, then their name alone («سارة»), so the patient sees at a
/// glance when, and by whom, before reading the name.
class SimplifiedDoneLine extends StatelessWidget {
  const SimplifiedDoneLine({
    super.key,
    required this.task,
    required this.day,
    required this.style,
  });

  final TodayTask task;
  final SimplifiedDay day;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final SimplifiedDone? done = simplifiedDone(task);
    final String at = simplifiedDoneAt(context, done);
    final String? by = simplifiedDoneBy(context, done, day);
    if (done == null || by == null) return Text(at, style: style);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: <Widget>[
        Text('$at،', style: style),
        PersonPhoto(
          name: done.name ?? '',
          photoPath: personPhotoPath(day.circleId, done.accountId),
          avatarCode: done.avatarCode,
          size: 26,
        ),
        Text(by, style: style),
      ],
    );
  }
}
