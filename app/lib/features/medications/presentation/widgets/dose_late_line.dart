import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
