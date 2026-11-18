import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/medication_row.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

const List<int> _columnFlex = <int>[4, 3, 2, 5];

/// The medicines as two tables, the current ones and then the ones that
/// ended, so a reader compares a column down the page instead of reading a
/// block for every medicine.
RecordPdfSection medicationSection(
  BuildContext context,
  RecordExportData data,
) {
  final DateTime today = data.today;
  final List<MedicationPlan> current = data.plans
      .where((MedicationPlan p) => !p.isPreviousOn(today))
      .toList();
  final List<MedicationPlan> previous = data.plans
      .where((MedicationPlan p) => p.isPreviousOn(today))
      .toList();
  final List<RecordPdfTable> tables = <RecordPdfTable>[
    if (current.isNotEmpty)
      _table(context, context.tr('record_export.current_medications'), current),
    if (previous.isNotEmpty)
      _table(
        context,
        context.tr('record_export.previous_medications'),
        previous,
      ),
  ];
  return RecordPdfSection(
    title: context.tr('record_export.medications'),
    tables: tables,
    empty: tables.isEmpty ? context.tr('medications.no_records') : null,
  );
}

RecordPdfTable _table(
  BuildContext context,
  String title,
  List<MedicationPlan> plans,
) {
  plans.sort(
    (MedicationPlan a, MedicationPlan b) =>
        a.version.name.compareTo(b.version.name),
  );
  return RecordPdfTable(
    title: title,
    headers: <String>[
      context.tr('record_export.col_medicine'),
      context.tr('record_export.col_strength'),
      context.tr('record_export.col_form'),
      context.tr('record_export.col_times'),
    ],
    flex: _columnFlex,
    rows: <List<RecordPdfCell>>[
      for (final MedicationPlan plan in plans) medicationRow(context, plan),
    ],
  );
}
