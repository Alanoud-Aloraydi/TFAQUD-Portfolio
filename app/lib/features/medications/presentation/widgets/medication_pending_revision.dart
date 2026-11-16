import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/pending_revision_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The change that waits for its first day, on the medicine's own page: what
/// it will be, and «إلغاء التعديل» for a member who may drop it.
class MedicationPendingRevision extends StatelessWidget {
  const MedicationPendingRevision({
    super.key,
    required this.plan,
    required this.circleId,
    required this.canManage,
    required this.onCancel,
  });

  final MedicationPlan plan;
  final String circleId;
  final bool canManage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppSemanticColors.textSupporting, width: 2),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PendingRevisionLines(
              pending: plan.pendingVersion!,
              circleId: circleId,
            ),
            if (canManage)
              TextButton(
                onPressed: onCancel,
                child: Text(context.tr('medications.cancel_pending')),
              ),
          ],
        ),
      ),
    );
  }
}
