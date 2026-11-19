import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/medications/domain/entities/extra_dose.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

const List<int> _columnFlex = <int>[3, 2, 4, 3, 3];

/// «جرعات إضافية» in the exported record: every dose of «سجّل جرعة الآن»,
/// oldest first, each with its medicine, on the patient's clock.
RecordPdfTable extraDoseTable(BuildContext context, RecordExportData data) {
  final Map<String, String> names = <String, String>{
    for (final plan in data.plans) plan.id: plan.version.name,
  };
  final List<ExtraDose> doses = <ExtraDose>[...data.extraDoses]
    ..sort((ExtraDose a, ExtraDose b) => a.takenAt.compareTo(b.takenAt));
  return RecordPdfTable(
    title: context.tr('medications.extra_doses'),
    headers: <String>[
      context.tr('record_export.col_date'),
      context.tr('record_export.col_time'),
      context.tr('record_export.col_medicine'),
      context.tr('medications.dose_value'),
      context.tr('record_export.recorded_by'),
    ],
    flex: _columnFlex,
    rows: <List<RecordPdfCell>>[
      for (final ExtraDose dose in doses)
        <RecordPdfCell>[
          RecordPdfCell(
            formatBirthDate(context, data.clock.wallTime(dose.takenAt)),
          ),
          RecordPdfCell(
            wallTimeText(data.clock.wallTime(dose.takenAt)),
            ltr: true,
          ),
          RecordPdfCell(names[dose.planId] ?? ''),
          RecordPdfCell(
            formatMedicationDose(context, dose.doseValue, dose.doseUnit),
          ),
          RecordPdfCell(dose.recordedByName ?? ''),
        ],
    ],
  );
}
