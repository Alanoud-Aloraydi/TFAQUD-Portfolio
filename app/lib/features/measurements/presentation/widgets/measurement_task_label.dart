import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The badge text of [task]'s status; [truly] says a missed task is older
/// and truly missed, not just not recorded yet.
String measurementTaskLabel(
  BuildContext context,
  MeasurementOccurrence task, {
  required bool truly,
}) => switch (task.status) {
  MeasurementStatus.read => context.tr('today_dashboard.status.recorded'),
  MeasurementStatus.readLate => context.tr('today_dashboard.status.recorded'),
  MeasurementStatus.skipped => context.tr('today_dashboard.status.skipped'),
  MeasurementStatus.missed => context.tr(
    truly ? 'measurements.missed' : 'measurements.unrecorded',
  ),
  MeasurementStatus.due => context.tr('today_dashboard.status.due'),
  MeasurementStatus.upcoming => context.tr('today_dashboard.status.upcoming'),
};
