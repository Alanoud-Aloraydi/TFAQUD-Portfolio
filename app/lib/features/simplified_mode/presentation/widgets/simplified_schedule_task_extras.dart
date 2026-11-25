import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_text.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_mark.dart';
import 'package:flutter/material.dart';

/// What a schedule row adds under its name and time: how to take it, and
/// who comes along to a visit.
class SimplifiedScheduleTaskExtras extends StatelessWidget {
  const SimplifiedScheduleTaskExtras({
    super.key,
    required this.task,
    required this.day,
  });

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    final String? how = simplifiedScheduleHow(
      context,
      task,
      day,
      companions: false,
    );
    final List<AppointmentCompanion> companions =
        task.appointment?.companions ?? const <AppointmentCompanion>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (how != null)
          Text(
            how,
            style: SimplifiedStyle.text(
              SimplifiedStyle.caption,
              color: SimplifiedColors.muted,
            ),
          ),
        if (companions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SimplifiedCompanions(
              circleId: day.circleId,
              companions: companions,
            ),
          ),
      ],
    );
  }
}

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
