import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_history_outcome.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_timing_badge.dart';
import 'package:flutter/material.dart';

/// The top line of a dose in the history: its time (for a dose taken, the
/// time it really was), and in the corner what became of it with who
/// recorded it, or, unrecorded, its timing.
class DoseHistoryHeading extends StatelessWidget {
  const DoseHistoryHeading({
    super.key,
    required this.occurrence,
    required this.status,
    this.circleId,
  });

  final DoseOccurrence occurrence;

  /// Its pill as «جدول اليوم» says it; null while nobody recorded it.
  final DoseRowStatus? status;
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    final PatientClock clock = PatientClockScope.of(context);
    final DoseRecord? record = occurrence.record;
    final DateTime? taken = record?.takenAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          taken == null
              ? clockText(occurrence.time)
              : wallTimeText(clock.wallTime(taken)),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: AppTextTheme.bold,
            color: AppSemanticColors.textPrimary,
          ),
        ),
        const Spacer(),
        if ((record, status) case (final DoseRecord r, final DoseRowStatus s))
          DoseHistoryOutcome(record: r, status: s, circleId: circleId)
        else
          DoseTimingBadge(
            state: occurrence.timingState,
            scheduledOn: occurrence.scheduledOn,
          ),
      ],
    );
  }
}
