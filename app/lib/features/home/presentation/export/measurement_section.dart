import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_level.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_skip_sheet.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

const List<int> _columnFlex = <int>[3, 2, 2, 3, 2, 4];

/// Readings as one table per kind, oldest first as a chart would read, with
/// every time on the patient's clock.
RecordPdfSection measurementSection(
  BuildContext context,
  RecordExportData data,
) {
  final List<RecordPdfTable> tables = <RecordPdfTable>[
    for (final MeasurementKind kind in MeasurementKind.values)
      if (_readingsOf(data, kind) case final readings when readings.isNotEmpty)
        _table(context, data, kind, readings),
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

RecordPdfTable _table(
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
      for (final MeasurementReading r in readings) _row(context, data, r),
    ],
  );
}

List<RecordPdfCell> _row(
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
    RecordPdfCell(_status(context, reading), warn: outside),
    RecordPdfCell(switch (reading.range) {
      final range? when !skipped => normalBandNumbers(
        reading.kind,
        range.normal,
      ),
      _ => '—',
    }, ltr: true),
    RecordPdfCell(_notes(context, reading)),
  ];
}

String _status(BuildContext context, MeasurementReading reading) {
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

String _notes(BuildContext context, MeasurementReading reading) {
  final List<String> parts = <String>[
    if (reading.outcome == 'read' && reading.conditions.isNotEmpty)
      readingConditionsText(context, reading),
    if (reading.outcome == 'skipped' && reading.skipReasonCode != null)
      measurementSkipReasonText(context, reading),
    if (reading.note?.isNotEmpty == true) reading.note!,
  ];
  return parts.isEmpty ? '—' : parts.join('، ');
}
