import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/measurements/domain/measurement_occurrence.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_answer.dart';
import 'package:flutter/material.dart';

/// A missed task's kind and time, and its day under them, as a reading's
/// titles are.
class MeasurementTaskTitle extends StatelessWidget {
  const MeasurementTaskTitle({super.key, required this.task});

  final MeasurementOccurrence task;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${measurementKindTitle(context, task.kind)} · '
            '${clockText(task.time)}',
            style: text.titleMedium,
            semanticsLabel: spoken(
              '${measurementKindTitle(context, task.kind)}، '
              '${clockText(task.time)}',
            ),
          ),
          Text(
            formatMedicationDate(context, task.scheduledOn),
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
