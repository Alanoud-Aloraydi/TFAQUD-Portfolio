import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What the calendar shows under it for the chosen [day] of [month]: the
/// date, and its [readings] or a note that there are none.
List<Widget> measurementCalendarSelection(
  BuildContext context, {
  required int day,
  required DateTime month,
  required List<MeasurementReading> readings,
  required String circleId,
}) => <Widget>[
  const SizedBox(height: AppSpacing.sm),
  Text(
    '$day ${context.tr('circles.months.${month.month}')}',
    style: Theme.of(context).textTheme.titleSmall,
  ),
  if (readings.isEmpty)
    EmptyStateNote(context.tr('measurements.no_readings'))
  else
    for (final MeasurementReading reading in readings) ...<Widget>[
      MeasurementReadingTile(reading: reading, circleId: circleId),
      const SizedBox(height: AppSpacing.xs),
    ],
];
