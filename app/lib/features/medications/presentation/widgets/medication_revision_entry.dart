import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MedicationRevisionEntry extends StatelessWidget {
  const MedicationRevisionEntry({
    super.key,
    required this.version,
    required this.previous,
  });

  final MedicationVersion version;
  final MedicationVersion? previous;

  @override
  Widget build(BuildContext context) {
    final date = formatMedicationDate(context, version.effectiveFromOn);
    final before = previous == null ? null : _scheduleText(context, previous!);
    final after = _scheduleText(context, version);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        border: Border.all(color: AppSemanticColors.borderSubtle),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
              previous == null
                  ? 'medications.initial_version'
                  : 'medications.revised_on',
              args: [date],
            ),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${version.name} · '
            '${formatMedicationNumber(version.strengthValue)} '
            '${context.tr('medications.strength_display.${version.strengthUnit.name}')} · '
            '${context.tr('medications.form.${version.dosageForm.name}')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('medications.schedule_revision'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (before != null && before != after)
            Text(
              before,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(decoration: TextDecoration.lineThrough),
            ),
          Text(after, style: Theme.of(context).textTheme.bodyMedium),
          if (version.reason case final reason?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(reason, style: Theme.of(context).textTheme.bodySmall),
          ],
          if (version.instructions case final instructions?) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(instructions, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _scheduleText(BuildContext context, MedicationVersion item) => item
      .schedules
      .map((schedule) {
        final dose = formatMedicationDose(
          context,
          schedule.doseValue,
          schedule.doseUnit,
        );
        return '${clockText(schedule.time)} · $dose';
      })
      .join('، ');
}
