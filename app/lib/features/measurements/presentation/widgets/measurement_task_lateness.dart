import 'package:app/core/l10n/duration_text.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «بعد 5 ساعات من الموعد»; without the reading's time, «تسجّلت بعد
/// الموعد».
String measurementLateLine(BuildContext context, MeasurementOccurrence task) {
  final MeasurementReading? record = task.record;
  if (record == null) {
    return context.tr('today_dashboard.status.recorded_late');
  }
  final DateTime scheduled = PatientClockScope.of(context)
      .momentOf(task.scheduledOn, task.time);
  final Duration late = (record.measuredAt ?? record.recordedAt)
      .toUtc()
      .difference(scheduled.toUtc());
  return context.tr(
    'today_dashboard.status.late_line',
    args: <String>[lateByText(context, late)],
  );
}

/// Whether [task] was due before yesterday on the patient's calendar.
bool isOlderMeasurementTask(BuildContext context, MeasurementOccurrence task) {
  final DateTime yesterday = DateUtils.dateOnly(
    PatientClockScope.of(context).today(),
  ).subtract(const Duration(days: 1));
  return DateUtils.dateOnly(task.scheduledOn).isBefore(yesterday);
}
