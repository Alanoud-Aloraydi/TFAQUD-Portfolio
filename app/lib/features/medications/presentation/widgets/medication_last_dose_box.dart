import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/plan_fact_group.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «آخر جرعة»: when the last explicit dose of a medicine was taken or
/// skipped, by whom, and why it was skipped; or that none was recorded.
class MedicationLastDoseBox extends StatelessWidget {
  const MedicationLastDoseBox({
    super.key,
    required this.circleId,
    required this.last,
  });

  final String circleId;
  final MedicationLastRecord? last;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.bodySmall;
    final MedicationLastRecord? last = this.last;
    return PlanInfoBox(
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              medicationLastDoseText(context, circleId: circleId, last: last),
              style: small,
            ),
            if (last?.recordedByName case final String name)
              RecorderLine(
                name: name,
                photoPath: personPhotoPath(circleId, last!.recordedByAccountId),
                avatarCode: last.recordedByAvatarCode,
              ),
            if (last?.outcome == DoseOutcome.skipped &&
                last?.skipReasonCode != null)
              Text(
                context.tr(
                  'medications.skip_reason_line',
                  args: <String>[
                    doseSkipReasonLabel(
                      context,
                      last!.skipReasonCode,
                      last.skipReasonNote,
                    ),
                  ],
                ),
                style: small,
              ),
          ],
        ),
      ),
    );
  }
}

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
