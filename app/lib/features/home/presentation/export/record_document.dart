import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/record_pdf_model.dart';
import 'package:app/features/home/domain/record_export_data.dart';
import 'package:app/features/home/presentation/export/appointment_section.dart';
import 'package:app/features/home/presentation/export/dose_log_section.dart';
import 'package:app/features/home/presentation/export/measurement_section.dart';
import 'package:app/features/home/presentation/export/medication_section.dart';
import 'package:app/features/home/presentation/export/patient_section.dart';
import 'package:app/features/home/presentation/export/summary_section.dart';
import 'package:easy_localization/easy_localization.dart';
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
      if (file != null)
        patientSection(context, file, withContacts: options.contacts),
      if (options.medications || options.measurements || options.appointments)
        summarySection(context, data),
      if (options.measurements) measurementSection(context, data),
      if (options.medications) medicationSection(context, data),
      if (options.medications && options.detailed)
        doseLogSection(context, data),
      if (options.appointments) appointmentSection(context, data),
    ],
  );
}
