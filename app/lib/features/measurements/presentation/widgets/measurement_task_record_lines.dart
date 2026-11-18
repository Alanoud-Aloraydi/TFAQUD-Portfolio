import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The lines of the reading that answered a measurement task: its value,
/// when it was recorded, who recorded it, and why it was skipped.
List<Widget> measurementTaskRecordLines(
  BuildContext context,
  MeasurementReading record,
  PatientClock clock,
  String circleId,
) {
  final TextStyle? small = Theme.of(context).textTheme.bodySmall;
  return <Widget>[
    if (record.outcome == 'read')
      Text(record.valueText, style: Theme.of(context).textTheme.titleSmall),
    Text(
      context.tr(
        'measurements.recorded_at',
        args: <String>[wallTimeText(clock.wallTime(record.recordedAt))],
      ),
      style: small,
    ),
    if (record.recordedByName case final String name)
      RecorderLine(
        name: name,
        photoPath: personPhotoPath(circleId, record.recordedByAccountId),
        avatarCode: record.recordedByAvatarCode,
      ),
    if (record.outcome == 'skipped' && record.skipReasonCode != null)
      Text(
        context.tr(
          'measurements.skip_reason_line',
          args: <String>[measurementSkipReasonText(context, record)],
        ),
        style: small,
      ),
  ];
}
