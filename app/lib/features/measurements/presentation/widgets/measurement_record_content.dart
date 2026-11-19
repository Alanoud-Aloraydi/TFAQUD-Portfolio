import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/features/measurements/domain/measurement_kind.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_load_status.dart';
import 'package:app/features/measurements/presentation/cubit/measurement_readings_state.dart';
import 'package:app/features/measurements/presentation/measurement_record_filter.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_chart_card.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_readings_history.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_record_empty.dart';
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
