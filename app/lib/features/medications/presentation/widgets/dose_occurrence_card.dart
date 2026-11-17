import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_lines.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:flutter/material.dart';

/// One dose in a medicine's history, read as one sentence: its time right
/// above the medicine with its strength and dose beside the name, and in
/// the corner what became of it with who recorded it, as on «جدول اليوم».
class DoseOccurrenceCard extends StatelessWidget {
  const DoseOccurrenceCard({
    super.key,
    required this.occurrence,
    this.circleId,
  });

  final DoseOccurrence occurrence;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final DoseRowStatus? status = occurrence.record == null
        ? null
        : DoseRowStatus.of(
            context,
            occurrence,
            PatientClockScope.of(context).now(),
          );
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: MergeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: DoseOccurrenceLines(
                  occurrence: occurrence,
                  status: status,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DoseHistoryOutcome(
                occurrence: occurrence,
                status: status,
                circleId: circleId,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
