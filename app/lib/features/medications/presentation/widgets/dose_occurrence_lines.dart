import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_heading.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_notes.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:flutter/material.dart';

/// A dose of the history, read as one sentence, as «جدول اليوم» shows a
/// dose: its time with what became of it and who recorded it, then the
/// medicine, its strength, the dose and the note, then how late it was
/// taken or why it was skipped.
class DoseOccurrenceLines extends StatelessWidget {
  const DoseOccurrenceLines({
    super.key,
    required this.occurrence,
    this.circleId,
  });

  final DoseOccurrence occurrence;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final DoseRecord? record = occurrence.record;
    final DoseRowStatus? status = record == null
        ? null
        : DoseRowStatus.of(
            context,
            occurrence,
            PatientClockScope.of(context).now(),
          );
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DoseHistoryHeading(
            occurrence: occurrence,
            status: status,
            circleId: circleId,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(occurrence.name, style: text.titleMedium),
          Text(doseStrengthText(context, occurrence)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            formatMedicationDose(
              context,
              occurrence.doseValue,
              occurrence.doseUnit,
            ),
            style: text.bodySmall,
          ),
          if (occurrence.instructions case final String instructions)
            Text(instructions, style: text.bodySmall),
          if ((record, status) case (final DoseRecord r, final DoseRowStatus s))
            ...doseHistoryNotes(context, r, s),
        ],
      ),
    );
  }
}
