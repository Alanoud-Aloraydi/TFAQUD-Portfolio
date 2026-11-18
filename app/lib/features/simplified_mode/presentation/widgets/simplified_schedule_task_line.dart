import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_mark.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

/// A schedule row as drawn: a rule above, the task's mark, then its words.
class SimplifiedScheduleTaskLine extends StatelessWidget {
  const SimplifiedScheduleTaskLine({
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SimplifiedColors.chip)),
      ),
      child: Row(
        children: <Widget>[
          SimplifiedTaskMark(task: task, circleId: day.circleId),
          const SizedBox(width: 14),
          Expanded(
            child: SimplifiedScheduleTaskText(
              task: task,
              day: day,
              now: now,
              snoozed: snoozed,
            ),
          ),
        ],
      ),
    );
  }
}
