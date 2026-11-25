import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:app/features/home/domain/entities/export_period.dart';
import 'package:app/features/home/domain/entities/record_export_data.dart';
import 'package:app/features/home/presentation/cubit/record_export_collecting.dart';
import 'package:app/features/home/presentation/cubit/record_export_cubit.dart';
import 'package:app/features/home/presentation/widgets/record_export_actions.dart';
import 'package:app/features/home/presentation/widgets/record_export_sheet_content.dart';
import 'package:app/features/measurements/domain/entities/measurement_plan.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the export sheet holds while it is open: the period and the parts
/// of the record chosen. Needs a [RecordExportCubit] above it.
class RecordExportSheetBody extends StatefulWidget {
  const RecordExportSheetBody({
    super.key,
    required this.plans,
    required this.measurementPlans,
  });

  final List<MedicationPlan> plans;
  final List<MeasurementPlan> measurementPlans;

  @override
  State<RecordExportSheetBody> createState() => _RecordExportSheetBodyState();
}

class _RecordExportSheetBodyState extends State<RecordExportSheetBody>
    with RecordExportActions {
  @override
  RecordExportOptions options = const RecordExportOptions();
  @override
  ExportRange range = ExportRange.last30;
  @override
  ExportPeriod? custom;

  @override
  // The glass sheet draws the title and the line under it, and scrolls.
  Widget build(BuildContext context) =>
      BlocBuilder<RecordExportCubit, RecordExportState>(
        builder: (context, state) => RecordExportSheetContent(
          state: state,
          range: range,
          custom: custom,
          options: options,
          onRange: choose,
          onOptions: (value) => setState(() => options = value),
          onShare: share,
        ),
      );
}

/// A section as a row: a tap includes it or leaves it out, and a check at
/// its end marks it included, as in the app's other lists of choices. Null
/// [onChanged] greys it.
class RecordExportCheckRow extends StatelessWidget {
  const RecordExportCheckRow({
    super.key,
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
                  ActionIcons.check,
                  size: AppSizes.iconSmall,
                  color: AppSemanticColors.textPrimary,
                )
              : null,
        ),
      ),
    );
  }
}
