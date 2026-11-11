import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:flutter/material.dart';

/// What a measurement row says about its task: the badge text key and
/// colour, and the row tone. Red is for an older task that is truly missed;
/// a recent one is still yellow because it can be recorded.
class MeasurementTaskStatus {
  const MeasurementTaskStatus({
    required this.labelKey,
    required this.badge,
    required this.row,
  });

  factory MeasurementTaskStatus.of(
    BuildContext context,
    MeasurementOccurrence task,
  ) {
    final bool truly =
        task.status == MeasurementStatus.missed && _isOlder(context, task);
    return MeasurementTaskStatus(
      labelKey: switch (task.status) {
        MeasurementStatus.read => 'today_dashboard.status.recorded',
        MeasurementStatus.readLate => 'today_dashboard.status.recorded_late',
        MeasurementStatus.skipped => 'today_dashboard.status.skipped',
        MeasurementStatus.missed =>
          truly ? 'measurements.missed' : 'measurements.unrecorded',
        MeasurementStatus.due => 'today_dashboard.status.due',
        MeasurementStatus.upcoming => 'today_dashboard.status.upcoming',
      },
      badge: switch (task.status) {
        MeasurementStatus.missed when truly => TodayStatusTone.danger,
        MeasurementStatus.missed ||
        MeasurementStatus.due => TodayStatusTone.attention,
        MeasurementStatus.read ||
        MeasurementStatus.readLate => TodayStatusTone.success,
        _ => TodayStatusTone.neutral,
      },
      row: truly
          ? TodayRowTone.danger
          : task.status == MeasurementStatus.missed
          ? TodayRowTone.attention
          : TodayRowTone.normal,
    );
  }

  final String labelKey;
  final TodayStatusTone badge;
  final TodayRowTone row;

  static bool _isOlder(BuildContext context, MeasurementOccurrence task) {
    final DateTime yesterday = DateUtils.dateOnly(
      PatientClockScope.of(context).today(),
    ).subtract(const Duration(days: 1));
    return DateUtils.dateOnly(task.scheduledOn).isBefore(yesterday);
  }
}
