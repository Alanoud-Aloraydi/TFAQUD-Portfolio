import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_group.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:app/core/widgets/pickers/birth_date_sheet.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/presentation/cubit/record_export_collecting.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_body.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The export sheet's rows: the period, the parts of the record, why the
/// last try failed, and the share button.
class RecordExportSheetContent extends StatelessWidget {
  const RecordExportSheetContent({
    super.key,
    required this.state,
    required this.range,
    required this.custom,
    required this.options,
    required this.onRange,
    required this.onOptions,
    required this.onShare,
  });

  final RecordExportState state;
  final ExportRange range;
  final ExportPeriod? custom;
  final RecordExportOptions options;
  final ValueChanged<ExportRange> onRange;
  final ValueChanged<RecordExportOptions> onOptions;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RecordExportRangeField(range: range, custom: custom, onSelected: onRange),
      const SizedBox(height: AppSpacing.md),
      RecordExportOptionsList(
        options: options,
        hasMedicalFile: state.medicalFile != null,
        onChanged: onOptions,
      ),
      if (state.errorKey != null) ...[
        const SizedBox(height: AppSpacing.sm),
        // Lined up with the text of the rows above.
        InsetText(
          context.tr(state.errorKey!),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      FilledButton(
        onPressed:
            state.status == RecordExportStatus.ready &&
                !state.busy &&
                options.hasAnySection
            ? onShare
            : null,
        child: Text(context.tr('record_export.share')),
      ),
    ],
  );
}

/// «الفترة»: a row that opens the glass menu of the ready-made spans and
/// «فترة مخصصة», like every other menu of the app.
class RecordExportRangeField extends StatelessWidget {
  const RecordExportRangeField({
    super.key,
    required this.range,
    required this.custom,
    required this.onSelected,
  });

  final ExportRange range;
  final ExportPeriod? custom;
  final ValueChanged<ExportRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return InsetGroup(
      children: <Widget>[
        Builder(
          builder: (BuildContext anchor) => InsetRow(
            label: context.tr('record_export.period'),
            value: _label(context, range),
            showChevron: true,
            onTap: () => _open(anchor),
          ),
        ),
      ],
    );
  }

  Future<void> _open(BuildContext anchor) async {
    final ExportRange? picked = await showGlassMenu<ExportRange>(
      anchorContext: anchor,
      semanticLabel: anchor.tr('record_export.period'),
      sections: <List<GlassMenuItem<ExportRange>>>[
        <GlassMenuItem<ExportRange>>[
          for (final ExportRange value in ExportRange.values)
            GlassMenuItem<ExportRange>(
              value: value,
              label: anchor.tr('record_export.range.${value.name}'),
              selected: value == range,
            ),
        ],
      ],
    );
    if (picked != null) onSelected(picked);
  }

  String _label(BuildContext context, ExportRange value) {
    final ExportPeriod? own = custom;
    if (value == ExportRange.custom && own != null) {
      return '${formatBirthDate(context, own.start)} – '
          '${formatBirthDate(context, own.end)}';
    }
    return context.tr('record_export.range.${value.name}');
  }
}

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
