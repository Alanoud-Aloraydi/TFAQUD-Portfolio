import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_earlier.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The words of a dose in the history: its time right above the medicine,
/// whose strength and dose sit beside its name in small pills, then the
/// note, then how late it was taken or why it was skipped.
class DoseOccurrenceLines extends StatelessWidget {
  const DoseOccurrenceLines({super.key, required this.occurrence, this.status});

  final DoseOccurrence occurrence;

  /// Its pill as «جدول اليوم» says it; null while nobody recorded it.
  final DoseRowStatus? status;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DoseHistoryHeading(occurrence: occurrence),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(occurrence.name, style: text.titleMedium),
            for (final String fact in <String>[
              doseStrengthText(context, occurrence),
              formatMedicationDose(
                context,
                occurrence.doseValue,
                occurrence.doseUnit,
              ),
            ])
              FactPill(fact),
          ],
        ),
        if (occurrence.instructions case final String instructions)
          Text(instructions, style: text.bodySmall),
        if ((occurrence.record, status) case (
          final DoseRecord record,
          final DoseRowStatus pill,
        ))
          ...doseHistoryNotes(context, record, pill),
      ],
    );
  }
}

/// The small lines under a recorded dose of the history, the words
/// «جدول اليوم» uses: how long after its time it was taken, and why a
/// skipped dose was not taken.
List<Widget> doseHistoryNotes(
  BuildContext context,
  DoseRecord record,
  DoseRowStatus status,
) {
  final TextStyle? small = Theme.of(context).textTheme.bodySmall;
  return <Widget>[
    if (status.lateBy case final String lateBy) Text(lateBy, style: small),
    if (record.outcome == DoseOutcome.skipped && record.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: <String>[doseSkipReasonText(context, record)],
        ),
        style: small,
      ),
  ];
}
