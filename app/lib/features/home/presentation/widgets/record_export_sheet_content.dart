import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/features/home/domain/export_period.dart';
import 'package:app/features/home/domain/record_export_options.dart';
import 'package:app/features/home/presentation/cubit/record_export_state.dart';
import 'package:app/features/home/presentation/widgets/record_export_options_list.dart';
import 'package:app/features/home/presentation/widgets/record_export_range_field.dart';
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
