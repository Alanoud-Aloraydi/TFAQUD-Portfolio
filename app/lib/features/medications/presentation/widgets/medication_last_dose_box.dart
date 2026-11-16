import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/dose_skip_reason_text.dart';
import 'package:app/features/medications/presentation/widgets/medication_last_dose_text.dart';
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
