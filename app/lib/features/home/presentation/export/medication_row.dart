import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// One medicine's line in the exported record: its name, strength, form,
/// and every time of the day with its dose.
List<RecordPdfCell> medicationRow(BuildContext context, MedicationPlan plan) {
  final version = plan.version;
  // Every time of the day in one cell: «8:00 ص — قرص واحد».
  final String times = version.schedules
      .map(
        (schedule) =>
            '${clockText(schedule.time)} — '
            '${formatMedicationNumber(schedule.doseValue)} '
            '${context.tr('medications.unit.${schedule.doseUnit.name}')}',
      )
      .join('، ');
  return <RecordPdfCell>[
    RecordPdfCell(version.name),
    RecordPdfCell(
      '${formatMedicationNumber(version.strengthValue)} '
      '${version.strengthUnit.apiValue}',
      ltr: true,
    ),
    RecordPdfCell(context.tr('medications.form.${version.dosageForm.name}')),
    RecordPdfCell(times),
  ];
}
