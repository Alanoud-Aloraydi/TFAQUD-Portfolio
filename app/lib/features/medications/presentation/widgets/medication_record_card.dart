import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A record summary that keeps the last explicit dose separate from the plan.
class MedicationRecordCard extends StatelessWidget {
  const MedicationRecordCard({
    super.key,
    required this.circleId,
    required this.plan,
  });

  final String circleId;
  final MedicationPlan plan;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    final previous = plan.isPreviousOn(DateUtils.dateOnly(DateTime.now()));
    final last = plan.lastRecord;
    final takenLocal = last?.takenAt?.toUtc().add(const Duration(hours: 3));
    final lastDate = takenLocal ?? last?.scheduledOn;
    final lastTime = takenLocal == null
        ? last?.time
        : '${takenLocal.hour.toString().padLeft(2, '0')}:'
              '${takenLocal.minute.toString().padLeft(2, '0')}';
    return Material(
      color: AppSemanticColors.surfacePlan,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push(Routes.medicationDetails(circleId, plan.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: AppSizes.touch,
                    height: AppSizes.touch,
                    child: const Icon(CupertinoIcons.capsule),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          version.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          context.tr(
                            'medications.starts_on',
                            args: [
                              formatMedicationDate(context, version.startsOn),
                            ],
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatMedicationNumber(version.strengthValue)} '
                    '${version.strengthUnit.apiValue}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr(
                      previous
                          ? 'medications.previous_label'
                          : 'medications.current_label',
                    ),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppSemanticColors.surfaceContent,
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Text(
                  last == null
                      ? context.tr('medications.no_recorded_dose')
                      : context.tr(
                          last.outcome == DoseOutcome.taken
                              ? 'medications.last_taken_record'
                              : 'medications.last_skipped_record',
                          args: [
                            formatMedicationDate(context, lastDate!),
                            formatMedicationTime(context, lastTime!),
                          ],
                        ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('medications.full_record'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    size: AppSizes.iconCompact,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
