import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_actions.dart';
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

/// The switch of a chart card between the chart and the calendar.
class MeasurementChartSwitch extends StatelessWidget {
  const MeasurementChartSwitch({
    super.key,
    required this.calendar,
    required this.onChanged,
  });

  final bool calendar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => GlassSegmentedControl<bool>(
    segments: <bool, String>{
      false: context.tr('measurements.chart'),
      true: context.tr('measurements.calendar'),
    },
    selected: calendar,
    onChanged: onChanged,
  );
}
