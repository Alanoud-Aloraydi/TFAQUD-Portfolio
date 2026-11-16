import 'package:app/features/appointments/domain/appointment.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_companions.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_dose_line.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:flutter/material.dart';

/// Under a task's name on the home card: what to take, its short notes,
/// and who comes along to a visit, each one's photo before their name.
class SimplifiedTaskDetails extends StatelessWidget {
  const SimplifiedTaskDetails({
    super.key,
    required this.task,
    required this.day,
  });

  final TodayTask task;
  final SimplifiedDay day;

  @override
  Widget build(BuildContext context) {
    final List<String> notes = simplifiedTaskNotes(context, task, day);
    final List<AppointmentCompanion> companions =
        task.appointment?.companions ?? const <AppointmentCompanion>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (task.dose case final dose?) ...<Widget>[
          const SizedBox(height: 6),
          SimplifiedDoseLine(
            dose: dose,
            strength: simplifiedDoseReason(task, day) == null,
          ),
        ],
        if (notes.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String note in notes) SimplifiedChip(note),
            ],
          ),
        ],
        if (companions.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          SimplifiedCompanions(circleId: day.circleId, companions: companions),
        ],
      ],
    );
  }
}
