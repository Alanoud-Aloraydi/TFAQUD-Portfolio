import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_companions.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_schedule_task_texts.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:flutter/material.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';

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
