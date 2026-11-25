import 'package:app/core/localization/duration_text.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/dose_retention.dart';
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

/// «بعد 5 ساعات من الموعد», a line under the name: the badge stays the
/// short «تم أخذها» of every taken dose. Null unless the dose was taken
/// after its missed boundary.
String? doseLateLine(BuildContext context, DoseOccurrence occurrence) {
  final DoseRecord? record = occurrence.record;
  final PatientClock clock = PatientClockScope.of(context);
  final DateTime? takenAt = record?.takenAt;
  if (record?.outcome != DoseOutcome.taken ||
      takenAt == null ||
      !occurrence.isTakenLate(clock)) {
    return null;
  }
  final Duration late = takenAt.toUtc().difference(
    clock.momentOf(occurrence.scheduledOn, occurrence.time).toUtc(),
  );
  return context.tr(
    'today_dashboard.status.late_line',
    args: <String>[lateByText(context, late)],
  );
}

/// Why a recorded dose was not taken, in the words the sheet offered.
String doseSkipReasonText(BuildContext context, DoseRecord record) {
  return doseSkipReasonLabel(
    context,
    record.skipReasonCode,
    record.skipReasonNote,
  );
}

/// The reason behind [code], or the note itself when «أخرى» was chosen and
/// something was written. The server's older codes are read too.
String doseSkipReasonLabel(BuildContext context, String? code, String? note) {
  if (code == null) return '';
  if (code == 'other' && note?.isNotEmpty == true) {
    return note!;
  }
  final key = switch (code) {
    'side_effects' => 'sideEffects',
    'patient_refused' => 'patientRefused',
    _ => code,
  };
  return context.tr('medications.skip_reason.$key');
}
