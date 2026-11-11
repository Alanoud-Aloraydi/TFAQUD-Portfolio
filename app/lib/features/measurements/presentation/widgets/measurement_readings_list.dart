import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/layout/section_header.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_task_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Under the charts: the scheduled measurements nobody recorded, then every
/// reading of the month.
class MeasurementReadingsList extends StatelessWidget {
  const MeasurementReadingsList({
    super.key,
    required this.circleId,
    required this.readings,
    required this.missed,
  });

  final String circleId;
  final List<MeasurementReading> readings;
  final List<MeasurementOccurrence> missed;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty && missed.isEmpty) {
      return EmptyStateNote(context.tr('measurements.no_readings'));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (missed.isNotEmpty) ..._missed(context),
        for (final MeasurementReading reading in readings) ...<Widget>[
          MeasurementReadingTile(reading: reading, circleId: circleId),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  List<Widget> _missed(BuildContext context) => <Widget>[
    SectionHeader(context.tr('measurements.unrecorded_measurements')),
    const SizedBox(height: AppSpacing.sm),
    for (final MeasurementOccurrence task in missed) ...<Widget>[
      Text(
        formatBirthDate(context, task.scheduledOn),
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: AppSpacing.xs),
      MeasurementTaskRow(
        task: task,
        now: PatientClockScope.of(context).now(),
        circleId: circleId,
        readOnly: true,
      ),
      const SizedBox(height: AppSpacing.sm),
    ],
    const SizedBox(height: AppSpacing.md),
  ];
}
