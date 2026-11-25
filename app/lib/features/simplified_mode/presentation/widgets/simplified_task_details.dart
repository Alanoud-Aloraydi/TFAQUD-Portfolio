import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/features/appointments/domain/entities/appointment.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/simplified_mode/domain/entities/simplified_day.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_chip.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_family_member_photo.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_task_chips.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_texts.dart';
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

/// What to take of a dose, on one line: «حبة واحدة», and the strength
/// beside it when [strength] asks for it.
class SimplifiedDoseLine extends StatelessWidget {
  const SimplifiedDoseLine({
    super.key,
    required this.dose,
    required this.strength,
  });

  final DoseOccurrence dose;

  /// False when the medicine's reason is shown as a chip under this line
  /// («الكوليسترول»): the reason tells the medicines apart, so the
  /// strength is not repeated.
  final bool strength;

  @override
  Widget build(BuildContext context) => Wrap(
    crossAxisAlignment: WrapCrossAlignment.end,
    spacing: 10,
    children: <Widget>[
      Text(
        simplifiedDoseAmount(context, dose),
        style: SimplifiedStyle.head(SimplifiedStyle.headline),
      ),
      if (strength)
        Text(
          simplifiedStrength(context, dose),
          style: SimplifiedStyle.text(
            SimplifiedStyle.body,
            weight: AppTextTheme.medium,
          ),
        ),
    ],
  );
}
