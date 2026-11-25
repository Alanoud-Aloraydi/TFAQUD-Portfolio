import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The sections of «الملخص الصحي» the person includes, as rows with a check
/// on each chosen one. The file always carries the full detail.
class RecordExportOptionsList extends StatelessWidget {
  const RecordExportOptionsList({
    super.key,
    required this.options,
    required this.hasMedicalFile,
    required this.onChanged,
  });

  final RecordExportOptions options;

  /// Without the patient's file loaded there is nothing to include for it.
  final bool hasMedicalFile;
  final ValueChanged<RecordExportOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetGroup(
          children: <Widget>[
            RecordExportCheckRow(
              label: context.tr('record_export.medical_file'),
              checked: hasMedicalFile && options.patient,
              onChanged: hasMedicalFile
                  ? (bool v) => onChanged(options.copyWith(patient: v))
                  : null,
            ),
            RecordExportCheckRow(
              label: context.tr('record_export.measurements'),
              checked: options.measurements,
              onChanged: (bool v) =>
                  onChanged(options.copyWith(measurements: v)),
            ),
            RecordExportCheckRow(
              label: context.tr('record_export.medications'),
              checked: options.medications,
              onChanged: (bool v) =>
                  onChanged(options.copyWith(medications: v)),
            ),
            if (options.medications)
              RecordExportCheckRow(
                label: context.tr('record_export.dose_log_option'),
                checked: options.doseLog,
                onChanged: (bool v) => onChanged(options.copyWith(doseLog: v)),
              ),
            RecordExportCheckRow(
              label: context.tr('record_export.appointments'),
              checked: options.appointments,
              onChanged: (bool v) =>
                  onChanged(options.copyWith(appointments: v)),
            ),
          ],
        ),
      ],
    );
  }
}
