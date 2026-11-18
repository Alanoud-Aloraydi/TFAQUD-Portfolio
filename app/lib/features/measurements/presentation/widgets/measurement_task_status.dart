import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_label.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_lateness.dart';
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
        task.status == MeasurementStatus.missed &&
        isOlderMeasurementTask(context, task);
    return MeasurementTaskStatus(
      label: measurementTaskLabel(context, task, truly: truly),
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
          ? measurementLateLine(context, task)
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
}
