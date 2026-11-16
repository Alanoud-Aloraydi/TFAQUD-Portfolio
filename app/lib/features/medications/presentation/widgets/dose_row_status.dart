import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_late_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What a dose row says about the dose: the badge text and colour, and
/// whether the row itself turns yellow (a dose nobody recorded). A dose
/// taken after its missed boundary says how long after its time, on a line
/// of its own ([lateBy]).
class DoseRowStatus {
  const DoseRowStatus({
    required this.label,
    required this.tone,
    required this.unrecorded,
    this.lateBy,
  });

  factory DoseRowStatus.of(
    BuildContext context,
    DoseOccurrence occurrence,
    DateTime now,
  ) {
    final DoseTimingState? timing = medicationTimingState(occurrence, now);
    final DoseRecord? record = occurrence.record;
    final String label = record == null
        ? context.tr('today_dashboard.status.${timing!.name}')
        : record.outcome == DoseOutcome.skipped
        ? context.tr('today_dashboard.status.skipped')
        : context.tr('today_dashboard.status.taken');
    final bool waiting =
        timing == DoseTimingState.due || timing == DoseTimingState.late;
    final bool unrecorded = timing == DoseTimingState.missed;
    return DoseRowStatus(
      label: label,
      lateBy: doseLateLine(context, occurrence),
      tone: switch (record?.outcome) {
        DoseOutcome.taken => StatusTone.success,
        DoseOutcome.skipped => StatusTone.muted,
        null => waiting || unrecorded ? StatusTone.attention : StatusTone.info,
      },
      unrecorded: record == null && unrecorded,
    );
  }

  final String label;
  final StatusTone tone;
  final bool unrecorded;

  /// How long after its time a late dose was taken; null otherwise.
  final String? lateBy;
}
