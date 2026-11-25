import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/presentation/widgets/appointment_section.dart';
import 'package:app/features/home/presentation/widgets/extra_dose_table.dart';
import 'package:app/features/home/presentation/widgets/measurement_section.dart';
import 'package:app/features/home/presentation/widgets/medication_section.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_row_status.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

/// One dose's line in the exported record: the day, the time, what became
/// of it, who recorded it and why it was skipped.
List<RecordPdfCell> doseLogRow(
  BuildContext context,
  RecordExportData data,
  DoseOccurrence dose,
) {
  final DoseRecord? record = dose.record;
  final bool taken = record?.outcome == DoseOutcome.taken;
  return <RecordPdfCell>[
    RecordPdfCell(formatBirthDate(context, dose.scheduledOn)),
    RecordPdfCell(clockText(dose.time), ltr: true),
    // A dose that was not taken is the line a reader is looking for.
    RecordPdfCell(_status(context, data, dose), warn: !taken),
    RecordPdfCell(record?.recordedByName ?? ''),
    RecordPdfCell(
      record != null &&
              record.outcome == DoseOutcome.skipped &&
              record.skipReasonCode != null
          ? doseSkipReasonText(context, record)
          : '',
    ),
  ];
}

String _status(
  BuildContext context,
  RecordExportData data,
  DoseOccurrence dose,
) {
  final DoseOutcome? outcome = dose.record?.outcome;
  if (outcome == DoseOutcome.taken) {
    return context.tr('today_dashboard.status.taken');
  }
  if (outcome == DoseOutcome.skipped) {
    return context.tr('today_dashboard.status.skipped');
  }
  final DateTime yesterday = DateTime(
    data.today.year,
    data.today.month,
    data.today.day - 1,
  );
  final bool old = DateUtils.dateOnly(dose.scheduledOn).isBefore(yesterday);
  return context.tr(
    old ? 'medications.timing.missed' : 'medications.timing.unrecorded',
  );
}
