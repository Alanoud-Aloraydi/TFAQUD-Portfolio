import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_schedule.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_reading_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_extras.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:flutter/material.dart';

class SimplifiedScheduleTaskRow extends StatelessWidget {
  const SimplifiedScheduleTaskRow({
    super.key,
    required this.task,
    required this.day,
    required this.now,
    required this.snoozed,
    required this.schedule,
  });

  final TodayTask task;
  final SimplifiedDay day;

  /// The patient's moment, for how long a task has been late.
  final DateTime now;

  /// «سأذكّرك 2:09 مساءً» in place of the status while the task is put off.
  final String? snoozed;

  /// Says whether the task can still be recorded, by the same rule «اليوم»
  /// follows.
  final TodaySchedule schedule;

  /// A task the patient can answer from here, as in the detailed mode: a
  /// dose, a reading or a visit opens its reminder, from an hour before
  /// its time until it is recorded.
  bool get _recordable => schedule.canRecord(task);

  @override
  Widget build(BuildContext context) {
    // One stop for the whole row.
    return Semantics(
      label: spoken(
        simplifiedScheduleLines(context, task, day, now, snoozed).join('، '),
      ),
      button: _recordable,
      onTap: _recordable
          ? () => openSimplifiedTask(context, task, day.circleId)
          : null,
      excludeSemantics: true,
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final Widget row = SimplifiedScheduleTaskLine(
      task: task,
      day: day,
      now: now,
      snoozed: snoozed,
    );
    if (!_recordable) return row;
    return InkWell(
      onTap: () => openSimplifiedTask(context, task, day.circleId),
      child: row,
    );
  }
}
