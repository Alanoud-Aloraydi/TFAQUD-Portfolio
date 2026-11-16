import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:flutter/material.dart';

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
