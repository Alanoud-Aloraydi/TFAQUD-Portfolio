import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/measurement_row.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

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
