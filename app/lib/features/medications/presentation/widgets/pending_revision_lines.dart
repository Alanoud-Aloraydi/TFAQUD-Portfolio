import 'package:app/core/l10n/arabic_counts.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/widgets/pending_schedule_lines.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The whole revision reads as one sentence: the day it takes over, what it
/// means for the patient, and the medicine as it will be then.
/// «إلغاء التعديل» stays a button of its own, outside this.
class PendingRevisionLines extends StatelessWidget {
  const PendingRevisionLines({
    super.key,
    required this.pending,
    required this.circleId,
  });

  final MedicationVersion pending;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              'medications.pending_revision',
              args: [formatMedicationDate(context, pending.effectiveFromOn)],
            ),
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(CareVoice.tr(context, circleId, 'medications.effective_hint')),
          const SizedBox(height: AppSpacing.md),
          Text(pending.name, style: text.titleMedium),
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
          if (pending.instructions case final instructions?) Text(instructions),
          Text(
            arabicCount(
              context,
              ArabicCount.minutes,
              pending.missedAfterMinutes,
            ),
          ),
          ...pendingScheduleLines(context, pending.schedules),
        ],
      ),
    );
  }
}
