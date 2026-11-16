import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The sentence of «آخر جرعة». The day and the time are the patient's own:
/// a dose recorded with a moment is read on their clock, and one without
/// keeps the time it was scheduled for.
String medicationLastDoseText(
  BuildContext context, {
  required String circleId,
  required MedicationLastRecord? last,
}) {
  if (last == null) return context.tr('medications.no_recorded_dose');
  final DateTime? taken = last.takenAt == null
      ? null
      : PatientClockScope.of(context).wallTime(last.takenAt!);
  return CareVoice.tr(
    context,
    circleId,
    last.outcome == DoseOutcome.taken
        ? 'medications.last_taken_record'
        : 'medications.last_skipped_record',
    args: <String>[
      formatMedicationDate(context, taken ?? last.scheduledOn),
      taken == null ? clockText(last.time) : wallTimeText(taken),
    ],
  );
}
