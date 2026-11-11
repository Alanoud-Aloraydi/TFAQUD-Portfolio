import 'package:app/features/home/domain/record_export_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The sections of the record the person can include, and how detailed.
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
      children: <Widget>[
        SegmentedButton<bool>(
          segments: <ButtonSegment<bool>>[
            ButtonSegment(
              value: false,
              label: Text(context.tr('record_export.mode.summary')),
            ),
            ButtonSegment(
              value: true,
              label: Text(context.tr('record_export.mode.detailed')),
            ),
          ],
          selected: <bool>{options.detailed},
          onSelectionChanged: (v) =>
              onChanged(options.copyWith(detailed: v.first)),
        ),
        _check(
          context,
          'record_export.medical_file',
          hasMedicalFile && options.patient,
          hasMedicalFile
              ? (v) => onChanged(options.copyWith(patient: v))
              : null,
        ),
        if (hasMedicalFile && options.patient)
          SwitchListTile(
            title: Text(context.tr('record_export.include_contacts')),
            value: options.contacts,
            onChanged: (v) => onChanged(options.copyWith(contacts: v)),
          ),
        _check(
          context,
          'record_export.measurements',
          options.measurements,
          (v) => onChanged(options.copyWith(measurements: v)),
        ),
        _check(
          context,
          'record_export.medications',
          options.medications,
          (v) => onChanged(options.copyWith(medications: v)),
        ),
        _check(
          context,
          'record_export.appointments',
          options.appointments,
          (v) => onChanged(options.copyWith(appointments: v)),
        ),
      ],
    );
  }

  Widget _check(
    BuildContext context,
    String titleKey,
    bool value,
    ValueChanged<bool>? onChanged,
  ) => CheckboxListTile(
    title: Text(context.tr(titleKey)),
    value: value,
    onChanged: onChanged == null ? null : (v) => onChanged(v ?? false),
  );
}
