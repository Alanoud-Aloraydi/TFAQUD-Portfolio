import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// «جدول 1» over the row, with the button that removes it. The button is
/// absent while the medicine has one schedule left.
class MedicationScheduleHeader extends StatelessWidget {
  const MedicationScheduleHeader({
    super.key,
    required this.index,
    this.onRemove,
  });

  final int index;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? remove = onRemove;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              context.tr(
                'medications.schedule_number',
                args: [(index + 1).toString()],
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (remove != null)
            IconButton(
              tooltip: context.tr('medications.remove_schedule'),
              onPressed: remove,
              color: AppSemanticColors.statusError,
              icon: const Icon(CupertinoIcons.delete),
            ),
        ],
      ),
    );
  }
}
