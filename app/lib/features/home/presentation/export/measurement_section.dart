import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/measurement_table.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Readings as one table per kind, oldest first as a chart would read, with
/// every time on the patient's clock.
RecordPdfSection measurementSection(
  BuildContext context,
  RecordExportData data,
) {
  final List<RecordPdfTable> tables = <RecordPdfTable>[
    for (final MeasurementKind kind in MeasurementKind.values)
      if (_readingsOf(data, kind) case final readings when readings.isNotEmpty)
        measurementTable(context, data, kind, readings),
  ];
  return RecordPdfSection(
    title: context.tr('record_export.measurements'),
    tables: tables,
    empty: tables.isEmpty ? context.tr('measurements.no_readings') : null,
  );
}

List<MeasurementReading> _readingsOf(
  RecordExportData data,
  MeasurementKind kind,
) {
  DateTime when(MeasurementReading r) => r.measuredAt == null
      ? r.scheduledOn!
      : data.clock.wallTime(r.measuredAt!);
  return data.readings.where((r) => r.kind == kind).toList()
    ..sort((a, b) => when(a).compareTo(when(b)));
}
