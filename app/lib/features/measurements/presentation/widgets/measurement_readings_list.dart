import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
