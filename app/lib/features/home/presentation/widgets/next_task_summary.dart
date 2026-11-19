import 'package:app/core/l10n/appointment_texts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/home/presentation/widgets/next_task_header.dart';
import 'package:app/features/home/presentation/widgets/today_next_task.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the next task is and when: its kind and name, the day and time, the
/// time left when it is within two days, and who goes with a visit.
class NextTaskSummary extends StatelessWidget {
  const NextTaskSummary({
    super.key,
    required this.task,
    required this.circleId,
    required this.now,
  });

  final NextTask task;
  final String circleId;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final measurement = task.measurement;
    final appointment = task.appointment;
    final minutes = (task.at.difference(now).inSeconds + 59) ~/ 60;
    final relative = afterDuration(context, minutes);
    final time =
        task.medication?.time ?? measurement?.time ?? appointment!.time;
    // What the task is reads as one sentence; the answer below stays
    // a button of its own.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NextTaskHeader(task: task, circleId: circleId),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${context.tr('common.weekdays.${task.at.weekday}')} '
            '${formatMedicationDate(context, task.at)}، '
            '${clockText(time)}',
            semanticsLabel: spoken(
              '${context.tr('common.weekdays.${task.at.weekday}')} '
              '${formatMedicationDate(context, task.at)}، '
              '${clockText(time)}',
            ),
          ),
          if (minutes < 2880)
            Text(relative, style: Theme.of(context).textTheme.titleMedium),
          if (appointment != null)
            Text(appointmentCompanionLine(context, appointment)),
        ],
      ),
    );
  }
}
