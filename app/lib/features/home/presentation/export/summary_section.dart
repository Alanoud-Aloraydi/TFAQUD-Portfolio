import 'package:app/features/home/data/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The counts of the period, only for the sections that were chosen. Each
/// count is a number, so it is set left to right.
RecordPdfSection summarySection(BuildContext context, RecordExportData data) {
  RecordPdfRow count(String key, int value) =>
      RecordPdfRow(label: context.tr(key), value: '$value', ltr: true);
  final options = data.options;
  return RecordPdfSection(
    title: context.tr('record_export.summary'),
    rows: <RecordPdfRow>[
      if (options.measurements) ...<RecordPdfRow>[
        count('record_export.measurement_count', data.takenReadings.length),
        count(
          'record_export.outside_count',
          data.readings.where((r) => r.outsideTarget == true).length,
        ),
      ],
      if (options.medications) ...<RecordPdfRow>[
        count('record_export.current_medications', data.currentMedications),
        count(
          'record_export.recorded_doses',
          data.doses.where((d) => d.record != null).length,
        ),
      ],
      if (options.medications || options.measurements)
        count(
          'record_export.missed_tasks',
          (options.medications ? data.missedDoses.length : 0) +
              (options.measurements ? data.missedTasks.length : 0),
        ),
      if (options.appointments)
        count('record_export.appointment_count', data.appointments.length),
    ],
  );
}
