import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
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

/// Who answered a recorded dose, with their photo beside the name. Shown
/// only inside a circle ([circleId]) and only once the server sent a name,
/// so a dose from before this was tracked keeps its three lines.
List<Widget> doseRecorderLine(
  BuildContext context, {
  required DoseRecord record,
  String? circleId,
}) {
  if (circleId == null) return const <Widget>[];
  final String? name = record.recordedByName;
  if (name == null) return const <Widget>[];
  return <Widget>[
    const SizedBox(height: AppSpacing.xs),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonPhoto(
          name: name,
          photoPath: personPhotoPath(circleId, record.recordedByAccountId),
          avatarCode: record.recordedByAvatarCode,
          size: AppSizes.iconSmall,
        ),
        const SizedBox(width: AppSpacing.tight),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  ];
}
