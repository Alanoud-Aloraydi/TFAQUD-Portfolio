import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/layout/plan_info_box.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «تعديل ينتظر»: the schedule the medicine has now, crossed out, and the
/// one that takes over on [pending]'s first day.
class MedicationPendingBox extends StatelessWidget {
  const MedicationPendingBox({
    super.key,
    required this.circleId,
    required this.current,
    required this.pending,
  });

  final String circleId;
  final MedicationVersion current;
  final MedicationVersion pending;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return PlanInfoBox(
      emphasis: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr(
              'medications.pending_revision',
              args: <String>[
                formatMedicationDate(context, pending.effectiveFromOn),
              ],
            ),
            style: text.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _summary(context, current.schedules),
            style: text.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(_summary(context, pending.schedules), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            CareVoice.tr(context, circleId, 'medications.effective_hint'),
            style: text.bodySmall,
          ),
        ],
      ),
    );
  }

  String _summary(
    BuildContext context,
    List<MedicationSchedule> schedules,
  ) => schedules
      .map(
        (schedule) =>
            '${clockText(schedule.time)} · '
            '${formatMedicationDose(context, schedule.doseValue, schedule.doseUnit)}',
      )
      .join('، ');
}
