import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_record_lines.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_snooze_text.dart';
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
