import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/measurements/domain/entities/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
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

const List<int> _columnFlex = <int>[3, 2, 2, 3, 2, 4];

/// The table of one kind of reading in the exported record.
RecordPdfTable measurementTable(
  BuildContext context,
  RecordExportData data,
  MeasurementKind kind,
  List<MeasurementReading> readings,
) {
  final bool bp = kind == MeasurementKind.bp;
  return RecordPdfTable(
    title: context.tr(bp ? 'measurements.bp' : 'measurements.glucose'),
    headers: <String>[
      context.tr('record_export.col_date'),
      context.tr('record_export.col_time'),
      context.tr(
        'record_export.col_value',
        args: <String>[
          context.tr(bp ? 'measurements.bp_unit' : 'measurements.glucose_unit'),
        ],
      ),
      context.tr('record_export.col_status'),
      context.tr('record_export.col_target'),
      context.tr('record_export.col_notes'),
    ],
    flex: _columnFlex,
    rows: <List<RecordPdfCell>>[
      for (final MeasurementReading r in readings)
        measurementRow(context, data, r),
    ],
  );
}

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
      // Only doses: the file carries what was recorded of the readings.
      if (options.medications)
        count('record_export.missed_tasks', data.missedDoses.length),
      if (options.appointments)
        count('record_export.appointment_count', data.appointments.length),
    ],
  );
}

/// One reading's line in the exported record: the day, the time, the value,
/// what it means, the normal band and the notes.
List<RecordPdfCell> measurementRow(
  BuildContext context,
  RecordExportData data,
  MeasurementReading reading,
) {
  final bool skipped = reading.outcome == 'skipped';
  final DateTime? at = reading.measuredAt == null
      ? null
      : data.clock.wallTime(reading.measuredAt!);
  final bool outside = reading.outsideTarget == true;
  return <RecordPdfCell>[
    RecordPdfCell(formatBirthDate(context, at ?? reading.scheduledOn!)),
    RecordPdfCell(at == null ? '—' : wallTimeText(at)),
    RecordPdfCell(skipped ? '—' : reading.valueText, ltr: true, warn: outside),
    RecordPdfCell(readingStatusText(context, reading), warn: outside),
    RecordPdfCell(switch (reading.range) {
      final range? when !skipped => normalBandNumbers(
        reading.kind,
        range.normal,
      ),
      _ => '—',
    }, ltr: true),
    RecordPdfCell(readingNotesText(context, reading)),
  ];
}

/// What a reading meant: skipped, its level, or where it fell against the
/// target.
String readingStatusText(BuildContext context, MeasurementReading reading) {
  if (reading.outcome == 'skipped') return context.tr('measurements.skipped');
  if (reading.level case final level?) {
    return level.label(context, reading.kind);
  }
  return context.tr(switch (reading.outsideTarget) {
    true => 'measurements.outside_target',
    false => 'measurements.in_target',
    null => 'measurements.without_target',
  });
}

/// The conditions it was read in, why it was skipped, and the typed note.
String readingNotesText(BuildContext context, MeasurementReading reading) {
  final List<String> parts = <String>[
    if (reading.outcome == 'read' && reading.conditions.isNotEmpty)
      readingConditionsText(context, reading),
    if (reading.outcome == 'skipped' && reading.skipReasonCode != null)
      measurementSkipReasonText(context, reading),
    if (reading.note?.isNotEmpty == true) reading.note!,
  ];
  return parts.isEmpty ? '—' : parts.join('، ');
}
