import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/domain/entities/normal_range.dart';
import 'package:app/features/measurements/presentation/widgets/condition_file_row.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:app/features/measurements/presentation/widgets/normal_range_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «سجل القياسات» under the charts: the month's [readings] gathered in a
/// box that folds away, as «سجل الجرعات» is, filtered by the month and by
/// who recorded (the kind is chosen at the top of the page).
class MeasurementReadingsHistory extends StatelessWidget {
  const MeasurementReadingsHistory({
    super.key,
    required this.circleId,
    required this.readings,
  });

  final String circleId;
  final List<MeasurementReading> readings;

  @override
  Widget build(BuildContext context) {
    final clock = PatientClockScope.of(context);
    return FilteredHistory<MeasurementReading>(
      title: context.tr('measurements.readings'),
      items: readings,
      // The day it was measured where the patient lives.
      dayOf: (r) => clock.wallTime(r.measuredAt ?? r.recordedAt),
      byOf: (r) => (r.recordedByAccountId, r.recordedByName),
      empty: EmptyStateNote(context.tr('measurements.no_readings')),
      builder: (shown) =>
          MeasurementReadingsList(circleId: circleId, readings: shown),
    );
  }
}

/// Under the charts: every reading of the month.
class MeasurementReadingsList extends StatelessWidget {
  const MeasurementReadingsList({
    super.key,
    required this.circleId,
    required this.readings,
  });

  final String circleId;
  final List<MeasurementReading> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return EmptyStateNote(context.tr('measurements.no_readings'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MeasurementReading reading in readings) ...<Widget>[
          MeasurementReadingTile(reading: reading, circleId: circleId),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// One card for each of [ranges], the last with where the condition comes
/// from and a row to change it in the medical file of [circleId].
class MeasurementRangeCards extends StatelessWidget {
  const MeasurementRangeCards({
    super.key,
    required this.circleId,
    required this.ranges,
  });

  final String circleId;
  final List<NormalRange> ranges;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final NormalRange range in ranges) ...[
        if (range != ranges.first) const SizedBox(height: 16),
        NormalRangeCard(
          range: range,
          footer: range == ranges.last
              ? context.tr('measurements.range_from_file')
              : null,
          action: range == ranges.last
              ? ConditionFileRow(circleId: circleId)
              : null,
        ),
      ],
    ],
  );
}
