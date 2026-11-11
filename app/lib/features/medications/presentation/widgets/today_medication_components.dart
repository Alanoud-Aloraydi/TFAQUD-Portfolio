import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/care_visuals.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/patient_clock.dart';
import 'package:app/core/widgets/feedback/attention_box.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_actions.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The one «يحتاج انتباهك» box of «اليوم»: the doses that need attention,
/// then [extra] (the measurements that need attention), under one title
/// whose number counts both.
class TodayMedicationAttentionSection extends StatefulWidget {
  const TodayMedicationAttentionSection({
    super.key,
    required this.occurrences,
    required this.circleId,
    required this.canManage,
    this.extra,
    this.extraCount = 0,
  });
  final List<DoseOccurrence> occurrences;
  final String circleId;

  /// Whether the viewer manages the circle's medicines, passed on to the
  /// medicine's page.
  final bool canManage;

  /// More cards after the doses, and how many they are.
  final Widget? extra;
  final int extraCount;

  @override
  State<TodayMedicationAttentionSection> createState() =>
      _TodayMedicationAttentionSectionState();
}

class _TodayMedicationAttentionSectionState
    extends State<TodayMedicationAttentionSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => AttentionBox(
    title: context.tr('today_dashboard.attention'),
    count: widget.occurrences.length + widget.extraCount,
    expanded: _expanded,
    onToggle: () => setState(() => _expanded = !_expanded),
    child: Column(
      children: [
        for (final item in widget.occurrences) ...[
          _AttentionMedicationCard(
            occurrence: item,
            circleId: widget.circleId,
            canManage: widget.canManage,
          ),
          if (item != widget.occurrences.last)
            const SizedBox(height: AppSpacing.sm),
        ],
        if (widget.extra case final Widget extra) ...[
          if (widget.occurrences.isNotEmpty)
            const SizedBox(height: AppSpacing.sm),
          extra,
        ],
      ],
    ),
  );
}

/// Renders the attention medication card element of today medication components.
class _AttentionMedicationCard extends StatelessWidget {
  const _AttentionMedicationCard({
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: context.tokens.error.withValues(alpha: .08),
                child: Icon(
                  TafaqodPhosphorIcons.pill,
                  color: context.tokens.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.tight),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.push(
                        Routes.medicationDetails(circleId, occurrence.planId),
                        extra: canManage,
                      ),
                      child: Text(
                        '${occurrence.name} ${_strength(context, occurrence)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${formatMedicationDate(context, occurrence.scheduledOn)}'
                      ' · ${clockText(occurrence.time)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      occurrence.instructions == null
                          ? dose
                          : '$dose · ${occurrence.instructions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DoseRecordControls(
            occurrence: occurrence,
            layout: DoseControlsLayout.attention,
            circleId: circleId,
          ),
        ],
      ),
    );
  }
}

/// Displays the today medication action dose UI.
class TodayMedicationActionDose extends StatelessWidget {
  const TodayMedicationActionDose({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });
  final DoseOccurrence occurrence;
  final String circleId;

  /// Passed on to the medicine's page.
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = PatientClockScope.of(context).now();
    final status = medicationTimingState(occurrence, now);
    final canRecord = canRecordOccurrence(
      resolved: occurrence.record != null,
      scheduledAt: wallClockAt(occurrence.scheduledOn, occurrence.time),
      now: now,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: AppSemanticColors.textSupporting, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicationPhotoBuilder(
            circleId: circleId,
            planId: occurrence.planId,
            builder: (context, bytes) => bytes == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: MedicationPhotoImage(bytes: bytes, height: 150),
                  ),
          ),
          Text(
            CareVoice.tr(context, circleId, switch (status) {
              DoseTimingState.due => 'today_dashboard.due_title',
              DoseTimingState.late => 'today_dashboard.late_title',
              _ => 'today_dashboard.next_dose',
            }),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
          const SizedBox(height: AppSpacing.tight),
          _NextDoseInfo(
            occurrence: occurrence,
            circleId: circleId,
            canManage: canManage,
          ),
          const SizedBox(height: AppSpacing.lg),
          TodayDoseWindow(occurrence: occurrence, now: now),
          if (canRecord) ...[
            const SizedBox(height: AppSpacing.md),
            DoseRecordControls(
              occurrence: occurrence,
              layout: DoseControlsLayout.today,
              circleId: circleId,
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders the next dose info element of today medication components.
class _NextDoseInfo extends StatelessWidget {
  const _NextDoseInfo({
    required this.occurrence,
    required this.circleId,
    required this.canManage,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final strength = _strength(context, occurrence);
    final dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final formattedTime = clockText(occurrence.time);
    final timeParts = formattedTime.split(' ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              timeParts.first,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            if (timeParts.length > 1)
              Text(
                timeParts.last,
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.push(
                  Routes.medicationDetails(circleId, occurrence.planId),
                  extra: canManage,
                ),
                child: Row(
                  children: [
                    const Icon(TafaqodPhosphorIcons.pill, size: 17),
                    const SizedBox(width: AppSpacing.tight),
                    Flexible(
                      child: Text(
                        '${occurrence.name} $strength',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                occurrence.instructions == null
                    ? dose
                    : '$dose · ${occurrence.instructions}',
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Displays the today medication prayer dose row UI.
class TodayMedicationPrayerDoseRow extends StatelessWidget {
  const TodayMedicationPrayerDoseRow({
    super.key,
    required this.occurrence,
    required this.circleId,
    required this.canManage,
    required this.now,
    this.showThumbnail = false,
  });

  final DoseOccurrence occurrence;
  final String circleId;

  /// Passed on to the medicine's page.
  final bool canManage;
  final DateTime now;
  final bool showThumbnail;

  @override
  Widget build(BuildContext context) {
    final status = medicationTimingState(occurrence, now);
    final isUnrecorded = status == DoseTimingState.missed;
    final record = occurrence.record;
    final label = record != null
        ? context.tr(
            record.outcome == DoseOutcome.skipped
                ? 'today_dashboard.status.skipped'
                : occurrence.isTakenLate(PatientClockScope.of(context))
                ? 'today_dashboard.status.taken_late'
                : 'today_dashboard.status.taken',
          )
        : context.tr('today_dashboard.status.${status!.name}');
    final isTaken = record?.outcome == DoseOutcome.taken;
    final isWaiting =
        status == DoseTimingState.due || status == DoseTimingState.late;
    final TodayStatusTone statusTone = isTaken
        ? TodayStatusTone.success
        : record != null
        ? TodayStatusTone.neutral
        : isWaiting || isUnrecorded
        ? TodayStatusTone.attention
        : TodayStatusTone.neutral;
    final dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    final canRecord = canRecordOccurrence(
      resolved: record != null,
      scheduledAt: wallClockAt(occurrence.scheduledOn, occurrence.time),
      now: now,
    );
    return TodayRowCard(
      tone: isUnrecorded ? TodayRowTone.attention : TodayRowTone.normal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 48,
                child: Text(
                  clockText(occurrence.time),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (showThumbnail) ...[
                MedicationPhotoBuilder(
                  circleId: circleId,
                  planId: occurrence.planId,
                  builder: (context, bytes) => bytes == null
                      ? Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: CareVisuals.medicationTile,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CareVisuals.medicationIcon,
                            size: AppSizes.iconSmall,
                          ),
                        )
                      : MedicationPhotoImage(
                          bytes: bytes,
                          width: 40,
                          height: 40,
                        ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else ...[
                const TodayTaskKindIcon(
                  icon: CareVisuals.medicationIcon,
                  background: CareVisuals.medicationTile,
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.push(
                        Routes.medicationDetails(circleId, occurrence.planId),
                        extra: canManage,
                      ),
                      child: Text(
                        '${occurrence.name} ${_strength(context, occurrence)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      occurrence.instructions == null
                          ? dose
                          : '$dose · ${occurrence.instructions}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (record?.recordedByName case final name?) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PersonPhoto(
                            name: name,
                            photoPath: personPhotoPath(
                              circleId,
                              record!.recordedByAccountId,
                            ),
                            avatarCode: record.recordedByAvatarCode,
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
                    if (record?.outcome == DoseOutcome.skipped &&
                        record?.skipReasonCode != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr(
                          'medications.skip_reason_line',
                          args: [doseSkipReasonText(context, record!)],
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              TodayTaskStatusBadge(text: label, tone: statusTone),
            ],
          ),
          if (canRecord) ...[
            const SizedBox(height: AppSpacing.sm),
            DoseRecordControls(
              occurrence: occurrence,
              layout: DoseControlsLayout.attention,
              circleId: circleId,
            ),
          ],
        ],
      ),
    );
  }
}

String _strength(BuildContext context, DoseOccurrence occurrence) =>
    '${formatMedicationNumber(occurrence.strengthValue)} '
    '${context.tr('medications.strength_display.${occurrence.strengthUnit.name}')}';
