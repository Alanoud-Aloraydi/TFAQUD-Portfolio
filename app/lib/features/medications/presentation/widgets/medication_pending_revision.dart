import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
    final pending = plan.pendingVersion!;
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
            Text(
              context.tr(
                'medications.pending_revision',
                args: [formatMedicationDate(context, pending.effectiveFromOn)],
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(CareVoice.tr(context, circleId, 'medications.effective_hint')),
            const SizedBox(height: AppSpacing.md),
            Text(pending.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              context.tr(
                'medications.pending_strength',
                args: [
                  formatMedicationNumber(pending.strengthValue),
                  context.tr(
                    'medications.strength_display.${pending.strengthUnit.name}',
                  ),
                  context.tr('medications.form.${pending.dosageForm.name}'),
                ],
              ),
            ),
            if (pending.instructions case final instructions?)
              Text(instructions),
            Text(
              arabicCount(
                context,
                ArabicCount.minutes,
                pending.missedAfterMinutes,
              ),
            ),
            for (final schedule in pending.schedules)
              Text(
                context.tr(
                  'medications.pending_schedule',
                  args: [
                    clockText(schedule.time),
                    formatMedicationNumber(schedule.doseValue),
                    context.tr('medications.unit.${schedule.doseUnit.name}'),
                  ],
                ),
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
