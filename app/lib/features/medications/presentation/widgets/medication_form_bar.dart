import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The form's own bar: «إلغاء», the title, and the green save button, on one
/// glass capsule.
class MedicationFormBar extends StatelessWidget {
  const MedicationFormBar({
    super.key,
    required this.isEdit,
    required this.saving,
    required this.onCancel,
    required this.onSave,
  });

  final bool isEdit;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(AppRadius.capsule),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            TextButton(
              onPressed: onCancel,
              child: Text(context.tr('common.cancel')),
            ),
            Expanded(
              child: Text(
                context.tr(
                  isEdit ? 'medications.edit_title' : 'medications.add_title',
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppSemanticColors.actionPrimary,
                  foregroundColor: AppSemanticColors.onActionPrimary,
                  minimumSize: const Size(58, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                ),
                onPressed: saving ? null : onSave,
                child: Text(context.tr('medications.save_changes')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
