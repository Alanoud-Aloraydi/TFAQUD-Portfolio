import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/features/home/domain/record_export_options.dart';
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
            _CheckRow(
              label: context.tr('record_export.medical_file'),
              checked: hasMedicalFile && options.patient,
              onChanged: hasMedicalFile
                  ? (bool v) => onChanged(options.copyWith(patient: v))
                  : null,
            ),
            if (hasMedicalFile && options.patient)
              _CheckRow(
                label: context.tr('record_export.include_contacts'),
                checked: options.contacts,
                onChanged: (bool v) => onChanged(options.copyWith(contacts: v)),
              ),
            _CheckRow(
              label: context.tr('record_export.measurements'),
              checked: options.measurements,
              onChanged: (bool v) =>
                  onChanged(options.copyWith(measurements: v)),
            ),
            _CheckRow(
              label: context.tr('record_export.medications'),
              checked: options.medications,
              onChanged: (bool v) =>
                  onChanged(options.copyWith(medications: v)),
            ),
            _CheckRow(
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

/// A section as a row: a tap includes it or leaves it out, and a check at
/// its end marks it included, as in the app's other lists of choices. Null
/// [onChanged] greys it.
class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    return Semantics(
      checked: checked,
      enabled: enabled,
      child: InsetRow(
        label: label,
        labelColor: enabled ? null : AppSemanticColors.borderControlBase,
        // The words take the row; the check (or its room) sits at the end.
        leading: const SizedBox.shrink(),
        onTap: enabled ? () => onChanged!(!checked) : null,
        trailing: SizedBox.square(
          dimension: AppSizes.iconSmall,
          child: checked
              ? const Icon(
                  AppIcons.check,
                  size: AppSizes.iconSmall,
                  color: AppSemanticColors.textPrimary,
                )
              : null,
        ),
      ),
    );
  }
}
