import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:app/features/medications/presentation/widgets/dose_skip_reason_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a dose row says under its two first lines: how late it was, who
/// recorded it, and the reason a skipped dose was not taken.
List<Widget> doseRowDetails(
  BuildContext context,
  DoseOccurrence occurrence,
  String circleId,
  DoseRowStatus status,
) {
  final DoseRecord? record = occurrence.record;
  return <Widget>[
    if (status.lateBy case final String lateBy)
      Text(lateBy, style: Theme.of(context).textTheme.bodySmall),
    if (record?.recordedByName case final String name)
      RecorderLine(
        name: name,
        photoPath: personPhotoPath(circleId, record!.recordedByAccountId),
        avatarCode: record.recordedByAvatarCode,
      ),
    if (record?.outcome == DoseOutcome.skipped &&
        record?.skipReasonCode != null)
      Text(
        context.tr(
          'medications.skip_reason_line',
          args: <String>[doseSkipReasonText(context, record!)],
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
  ];
}
