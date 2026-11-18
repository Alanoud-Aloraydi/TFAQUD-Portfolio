import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/dose_log_row.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const List<int> _columnFlex = <int>[3, 2, 3, 3, 4];

/// The doses of one medicine in the exported record, oldest first.
RecordPdfTable doseLogTable(
  BuildContext context,
  RecordExportData data,
  String name,
  List<DoseOccurrence> doses,
) {
  doses.sort((DoseOccurrence a, DoseOccurrence b) {
    final int day = a.scheduledOn.compareTo(b.scheduledOn);
    return day != 0 ? day : a.time.compareTo(b.time);
  });
  return RecordPdfTable(
    title: name,
    headers: <String>[
      context.tr('record_export.col_date'),
      context.tr('record_export.col_time'),
      context.tr('record_export.col_status'),
      context.tr('record_export.recorded_by'),
      context.tr('record_export.col_notes'),
    ],
    flex: _columnFlex,
    rows: <List<RecordPdfCell>>[
      for (final DoseOccurrence dose in doses) doseLogRow(context, data, dose),
    ],
  );
}
