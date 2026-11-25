import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/presentation/widgets/appointment_section.dart';
import 'package:app/features/home/presentation/widgets/dose_log_table.dart';
import 'package:app/features/home/presentation/widgets/extra_dose_table.dart';
import 'package:app/features/home/presentation/widgets/measurement_section.dart';
import 'package:app/features/home/presentation/widgets/medication_section.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// The exported record in the order a doctor reads it: who the patient is
/// and for which period (the header), the counts, the measurements, the
/// medicines, the dose log, then the appointments.
RecordPdfDocument buildRecordDocument(
  BuildContext context,
  RecordExportData data,
) {
  final options = data.options;
  final file = data.medicalFile;
  return RecordPdfDocument(
    appName: context.tr('auth.app_name'),
    title: context.tr('record_export.pdf_title'),
    header: <RecordPdfRow>[
      if (file != null)
        RecordPdfRow(
          label: context.tr('record_export.patient'),
          value: file.patient.fullName,
        ),
      RecordPdfRow(
        label: context.tr('record_export.period'),
        value:
            '${formatBirthDate(context, data.period.start)} – '
            '${formatBirthDate(context, data.period.end)}',
      ),
      RecordPdfRow(
        label: context.tr('record_export.time_zone'),
        value: data.clock.zone,
        ltr: true,
      ),
      RecordPdfRow(
        label: context.tr('record_export.export_date'),
        value: formatBirthDate(context, data.today),
      ),
    ],
    sections: <RecordPdfSection>[
      if (file != null) patientSection(context, file),
      if (options.medications || options.measurements || options.appointments)
        summarySection(context, data),
      if (options.measurements) measurementSection(context, data),
      if (options.medications) medicationSection(context, data),
      if (options.medications && options.doseLog) doseLogSection(context, data),
      if (options.appointments) appointmentSection(context, data),
    ],
  );
}

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
