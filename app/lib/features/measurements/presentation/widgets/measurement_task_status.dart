import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a measurement row says about its task: the badge text and colour,
/// and the row tone. A reading taken after its time says how long after on
/// a line of its own («بعد 5 ساعات من الموعد»). Red is for an older task
/// that is truly missed; a recent one is still yellow because it can be
/// recorded.
class MeasurementTaskStatus {
  const MeasurementTaskStatus({
    required this.label,
    required this.badge,
    required this.row,
    this.lateBy,
  });

  factory MeasurementTaskStatus.of(
    BuildContext context,
    MeasurementOccurrence task,
  ) {
    final bool truly =
        task.status == MeasurementStatus.missed && _isOlder(context, task);
    return MeasurementTaskStatus(
      label: switch (task.status) {
        MeasurementStatus.read => context.tr('today_dashboard.status.recorded'),
        MeasurementStatus.readLate => context.tr(
          'today_dashboard.status.recorded',
        ),
        MeasurementStatus.skipped => context.tr(
          'today_dashboard.status.skipped',
        ),
        MeasurementStatus.missed => context.tr(
          truly ? 'measurements.missed' : 'measurements.unrecorded',
        ),
        MeasurementStatus.due => context.tr('today_dashboard.status.due'),
        MeasurementStatus.upcoming => context.tr(
          'today_dashboard.status.upcoming',
        ),
      },
      badge: switch (task.status) {
        MeasurementStatus.missed when truly => StatusTone.danger,
        MeasurementStatus.missed ||
        MeasurementStatus.due => StatusTone.attention,
        MeasurementStatus.read ||
        MeasurementStatus.readLate => StatusTone.success,
        MeasurementStatus.skipped => StatusTone.muted,
        MeasurementStatus.upcoming => StatusTone.info,
      },
      lateBy: task.status == MeasurementStatus.readLate
          ? _lateLine(context, task)
          : null,
      row: truly
          ? TodayRowTone.danger
          : task.status == MeasurementStatus.missed
          ? TodayRowTone.attention
          : TodayRowTone.normal,
    );
  }

  final String label;
  final StatusTone badge;
  final TodayRowTone row;

  /// How long after its time a late reading was taken, a line under the
  /// title: the badge stays the short «تم تسجيلها».
  final String? lateBy;

  /// «بعد 5 ساعات من الموعد»; without the reading's time, «تسجّلت بعد
  /// الموعد».
  static String _lateLine(BuildContext context, MeasurementOccurrence task) {
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

  static bool _isOlder(BuildContext context, MeasurementOccurrence task) {
    final DateTime yesterday = DateUtils.dateOnly(
      PatientClockScope.of(context).today(),
    ).subtract(const Duration(days: 1));
    return DateUtils.dateOnly(task.scheduledOn).isBefore(yesterday);
  }
}
