import 'package:app/app/services/reminders/shared_snooze.dart';
import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/media/person_photo_editor.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/layout/recorder_line.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_snooze.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The lines under a measurement row's title: its condition, a snooze, and
/// the reading that answered it.
List<Widget> measurementTaskDetails(
  BuildContext context,
  MeasurementOccurrence task,
  String circleId,
) {
  final MeasurementReading? record = task.record;
  final clock = PatientClockScope.of(context);
  final String? putOff = measurementSnoozeText(context, task, clock);
  return <Widget>[
    if (task.measurementState != null)
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: StatusBadge(
          text: context.tr('measurements.condition.${task.measurementState}'),
          tone: StatusTone.neutral,
        ),
      ),
    if (putOff != null)
      MeasurementTaskSnooze(task: task, text: putOff, circleId: circleId),
    if (record != null)
      ...measurementTaskRecordLines(context, record, clock, circleId),
  ];
}

/// «ذكّرني لاحقًا» put off by someone in the circle, while it waits.
String? measurementSnoozeText(
  BuildContext context,
  MeasurementOccurrence task,
  PatientClock clock,
) {
  final SharedSnooze? snooze = task.snooze;
  if (snooze == null || task.record != null) return null;
  final DateTime until = clock.wallTime(snooze.remindAt);
  if (!until.isAfter(clock.now())) return null;
  final String time = wallTimeText(until);
  return snooze.byName == null
      ? context.tr('measurements.snoozed_shared', args: <String>[time])
      : context.tr(
          'measurements.snoozed_by',
          args: <String>[time, snooze.byName!],
        );
}

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
