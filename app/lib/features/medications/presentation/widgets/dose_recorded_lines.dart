import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_recorder_line.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The words inside a recorded dose's box: what was recorded, when, why it
/// was skipped, and who answered it. [ink] colours the first line.
List<Widget> doseRecordedLines(
  BuildContext context, {
  required DoseOccurrence occurrence,
  required Color ink,
  String? circleId,
}) {
  final DoseRecord record = occurrence.record!;
  final bool taken = record.outcome == DoseOutcome.taken;
  return <Widget>[
    // The patient reads «تم تسجيل إنك أخذت الجرعة»; someone
    // caring for them reads the patient's name instead.
    Text(
      CareVoice.tr(
        context,
        circleId,
        taken
            ? occurrence.isTakenLate(PatientClockScope.of(context))
                  ? 'medications.taken_late_status'
                  : 'medications.taken_status'
            : 'medications.skipped_status',
      ),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: ink),
    ),
    if (record.takenAt case final takenAt?)
      Text(
        context.tr(
          'medications.recorded_at',
          args: [_takenTime(context, takenAt)],
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    if (!taken && record.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: [doseSkipReasonText(context, record)],
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ...doseRecorderLine(context, record: record, circleId: circleId),
  ];
}

String _takenTime(BuildContext context, DateTime takenAt) {
  return wallTimeText(PatientClockScope.of(context).wallTime(takenAt));
}
