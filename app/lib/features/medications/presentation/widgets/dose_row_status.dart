import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What a dose row says about the dose: the badge text and colour, and
/// whether the row itself turns yellow (a dose nobody recorded).
class DoseRowStatus {
  const DoseRowStatus({
    required this.label,
    required this.tone,
    required this.unrecorded,
  });

  factory DoseRowStatus.of(
    BuildContext context,
    DoseOccurrence occurrence,
    DateTime now,
  ) {
    final DoseTimingState? timing = medicationTimingState(occurrence, now);
    final DoseRecord? record = occurrence.record;
    final String key = record == null
        ? 'today_dashboard.status.${timing!.name}'
        : record.outcome == DoseOutcome.skipped
        ? 'today_dashboard.status.skipped'
        : occurrence.isTakenLate(PatientClockScope.of(context))
        ? 'today_dashboard.status.taken_late'
        : 'today_dashboard.status.taken';
    final bool waiting =
        timing == DoseTimingState.due || timing == DoseTimingState.late;
    final bool unrecorded = timing == DoseTimingState.missed;
    return DoseRowStatus(
      label: context.tr(key),
      tone: record?.outcome == DoseOutcome.taken
          ? TodayStatusTone.success
          : record == null && (waiting || unrecorded)
          ? TodayStatusTone.attention
          : TodayStatusTone.neutral,
      unrecorded: record == null && unrecorded,
    );
  }

  final String label;
  final TodayStatusTone tone;
  final bool unrecorded;
}
