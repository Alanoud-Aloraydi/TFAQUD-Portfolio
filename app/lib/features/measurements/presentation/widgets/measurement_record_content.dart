import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/domain/entities/measurement_kind.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_loading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_tasks_loading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_attention_section.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_history.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What «السجل»'s measurements show for [state] under the filter and the
/// month: the first read, why it failed with [onRetry], the empty note with
/// [onAddReading], or a chart for each kind that has a reading in [month]
/// and the readings under them. A plan alone draws no chart.
List<Widget> measurementRecordContent(
  MeasurementReadingsState state, {
  required String circleId,
  required CalendarMonth month,
  required MeasurementRecordFilter filter,
  required VoidCallback onRetry,
  VoidCallback? onAddReading,
}) {
  if (state.status == MeasurementLoadStatus.initial ||
      (state.status == MeasurementLoadStatus.loading &&
          state.readings.isEmpty)) {
    return const <Widget>[LoadingNote()];
  }
  if (state.status == MeasurementLoadStatus.failure) {
    return <Widget>[
      RetryView(
        messageKey: state.errorKey ?? 'error.unknown',
        onRetry: onRetry,
      ),
    ];
  }
  final List<MeasurementReading> kept = <MeasurementReading>[
    for (final MeasurementReading r in state.readings)
      if (filter.keeps(r.kind)) r,
  ];
  if (kept.isEmpty) {
    return <Widget>[MeasurementRecordEmpty(onAdd: onAddReading)];
  }
  return <Widget>[
    for (final MeasurementKind kind in MeasurementKind.values)
      if (kept.any((r) => r.kind == kind && r.outcome == 'read')) ...<Widget>[
        MeasurementChartCard(
          kind: kind,
          readings: <MeasurementReading>[
            for (final MeasurementReading r in kept)
              if (r.kind == kind && r.outcome == 'read') r,
          ],
          month: month,
          circleId: circleId,
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    const SizedBox(height: AppSpacing.md),
    MeasurementReadingsHistory(circleId: circleId, readings: kept),
  ];
}

/// «السجل»'s readings when the month has none under the filter: the note,
/// with «تسجيل قراءة» for someone who may record one, as «الخطة» offers
/// its own add.
class MeasurementRecordEmpty extends StatelessWidget {
  const MeasurementRecordEmpty({super.key, this.onAdd});

  /// Opens the reading sheet; null hides the action.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => EmptyStateNote.section(
    context.tr('measurements.no_records'),
    actionLabel: onAdd == null
        ? null
        : context.tr('measurements.record_reading'),
    onAction: onAdd,
  );
}
