import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/simplified_task_status.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_done_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_snoozed_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_mark.dart';
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
