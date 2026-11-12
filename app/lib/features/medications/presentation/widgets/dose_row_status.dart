import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// What a dose row says about the dose: the badge text and colour, and
/// whether the row itself turns yellow (a dose nobody recorded). A dose
/// taken after its missed boundary says how long after its time.
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
    final PatientClock clock = PatientClockScope.of(context);
    final DateTime? takenAt = record?.takenAt;
    final String label = record == null
        ? context.tr('today_dashboard.status.${timing!.name}')
        : record.outcome == DoseOutcome.skipped
        ? context.tr('today_dashboard.status.skipped')
        : !occurrence.isTakenLate(clock) || takenAt == null
        ? context.tr('today_dashboard.status.taken')
        // «تم أخذها بعد 5 ساعات من الموعد».
        : context.tr(
            'today_dashboard.status.taken_late_by',
            args: <String>[
              lateByText(
                context,
                takenAt.toUtc().difference(
                  clock
                      .momentOf(occurrence.scheduledOn, occurrence.time)
                      .toUtc(),
                ),
              ),
            ],
          );
    final bool waiting =
        timing == DoseTimingState.due || timing == DoseTimingState.late;
    final bool unrecorded = timing == DoseTimingState.missed;
    return DoseRowStatus(
      label: label,
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
}
