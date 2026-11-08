import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/entities/medication_plan.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A record summary that keeps the last explicit dose separate from the plan.
class MedicationRecordCard extends StatelessWidget {
  const MedicationRecordCard({
    super.key,
    required this.circleId,
    required this.plan,
    required this.canManage,
  });

  final String circleId;
  final MedicationPlan plan;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final version = plan.version;
    final today = riyadhToday();
    final previous = plan.isPreviousOn(today);
    final scheduled = plan.isScheduledOn(today);
    final last = plan.lastRecord;
    final takenLocal = last?.takenAt == null ? null : riyadhNow(last!.takenAt);
    final lastDate = takenLocal ?? last?.scheduledOn;
    final lastTime = takenLocal == null
        ? last?.time
        : '${takenLocal.hour.toString().padLeft(2, '0')}:'
              '${takenLocal.minute.toString().padLeft(2, '0')}';
    final statusText = context.tr(
      previous
          ? 'medications.previous_label'
          : scheduled
          ? 'medications.scheduled_label'
          : 'medications.current_label',
    );
    return Material(
      color: AppSemanticColors.surfaceContent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppSemanticColors.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => context.push(
          Routes.medicationDetails(circleId, plan.id),
          extra: canManage,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  MedicationPhotoBuilder(
                    circleId: circleId,
                    planId: plan.id,
                    builder: (context, bytes) => bytes == null
                        ? Container(
                            width: 64,
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppSemanticColors.surfaceContent,
                              borderRadius: BorderRadius.circular(
                                AppRadius.field,
                              ),
                            ),
                            child: const Icon(TafaqodPhosphorIcons.pill),
                          )
                        : MedicationPhotoImage(
                            bytes: bytes,
                            width: 64,
                            height: 64,
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.xs,
                          children: [
                            Text(
                              version.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${formatMedicationNumber(version.strengthValue)} '
                              '${context.tr('medications.strength_display.${version.strengthUnit.name}')}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
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
                  CompactStatusBadge(
                    text: statusText,
                    background: previous || scheduled
                        ? AppSemanticColors.surfaceContent
                        : AppSemanticColors.selectedSurface,
                    foreground: AppSemanticColors.textPrimary,
                  ),
                ],
              ),
              if (plan.history.length > 1) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppSemanticColors.surfaceContent,
                    border: Border.all(color: AppSemanticColors.borderSubtle),
                    borderRadius: BorderRadius.circular(AppRadius.field),
                  ),
                  child: Text(
                    context.tr(
                      'medications.revised_on',
                      args: [
                        formatMedicationDate(
                          context,
                          plan.history.last.effectiveFromOn,
                        ),
                      ],
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppSemanticColors.surfaceContent,
                  border: Border.all(color: AppSemanticColors.borderSubtle),
                  borderRadius: BorderRadius.circular(AppRadius.field),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      last == null
                          ? context.tr('medications.no_recorded_dose')
                          : CareVoice.tr(
                              context,
                              circleId,
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
                    if (last?.recordedByName case final name?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PersonPhoto(
                            name: name,
                            photoPath: personPhotoPath(
                              circleId,
                              last!.recordedByAccountId,
                            ),
                            avatarCode: last.recordedByAvatarCode,
                            size: AppSizes.iconSmall,
                          ),
                          const SizedBox(width: AppSpacing.tight),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ],
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
                  const Icon(AppIcons.forward, size: AppSizes.iconSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
