import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_mark.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_status.dart';
import 'package:flutter/material.dart';

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
