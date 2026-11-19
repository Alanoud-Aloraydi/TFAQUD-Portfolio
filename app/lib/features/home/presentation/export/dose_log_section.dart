import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/dose_log_table.dart';
import 'package:app/features/home/presentation/export/extra_dose_table.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Every dose that was recorded or missed, as one table per medicine and
/// oldest first inside it, so a reader follows one medicine down the page
/// instead of meeting it again every few lines; then the extra doses.
RecordPdfSection doseLogSection(BuildContext context, RecordExportData data) {
  final Iterable<DoseOccurrence> visible = data.doses.where(
    (DoseOccurrence d) =>
        d.record != null || d.timingState == DoseTimingState.missed,
  );
  final Map<String, List<DoseOccurrence>> byMedicine =
      <String, List<DoseOccurrence>>{};
  for (final DoseOccurrence dose in visible) {
    byMedicine.putIfAbsent(dose.name, () => <DoseOccurrence>[]).add(dose);
  }
  final List<String> names = byMedicine.keys.toList()..sort();
  final List<RecordPdfTable> tables = <RecordPdfTable>[
    for (final String name in names)
      doseLogTable(context, data, name, byMedicine[name]!),
    if (data.extraDoses.isNotEmpty) extraDoseTable(context, data),
  ];
  return RecordPdfSection(
    title: context.tr('record_export.dose_log'),
    tables: tables,
    empty: tables.isEmpty ? context.tr('medications.no_dose_history') : null,
  );
}
