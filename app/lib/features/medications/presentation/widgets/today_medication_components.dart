import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/icons/tafaqod_phosphor_icons.dart';
import 'package:app/core/utils/riyadh_time.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/domain/dose_timing.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:app/features/medications/presentation/widgets/medication_photo_field.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/widgets/today_dose_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Displays the today medication attention section UI.
class TodayMedicationAttentionSection extends StatefulWidget {
  const TodayMedicationAttentionSection({
    super.key,
    required this.occurrences,
    required this.circleId,
  });
  final List<DoseOccurrence> occurrences;
  final String circleId;

  @override
  State<TodayMedicationAttentionSection> createState() =>
      _TodayMedicationAttentionSectionState();
}

class _TodayMedicationAttentionSectionState
    extends State<TodayMedicationAttentionSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppSemanticColors.surfaceAttention,
      border: Border.all(color: AppSemanticColors.borderAttention),
      borderRadius: BorderRadius.circular(AppRadius.m),
    ),
    child: Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppRadius.m),
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.tight),
            child: Row(
              children: [
                const Icon(
                  TafaqodPhosphorIcons.warning,
                  color: AppSemanticColors.statusWarning,
                  size: 17,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  context.tr('today_dashboard.attention'),
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(color: AppSemanticColors.statusWarning),
                ),
                const SizedBox(width: AppSpacing.sm),
                CircleAvatar(
                  radius: 11,
                  backgroundColor: AppSemanticColors.accentWarm,
                  child: Text(
                    widget.occurrences.length.toString(),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const Spacer(),
                Text(
                  context.tr(
                    _expanded
                        ? 'today_dashboard.hide_attention'
                        : 'today_dashboard.show_attention',
                  ),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  _expanded
                      ? TafaqodPhosphorIcons.caretUp
                      : TafaqodPhosphorIcons.caretDown,
                  size: 16,
                  color: AppSemanticColors.statusWarning,
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppMotion.disclosure,
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              for (final item in widget.occurrences) ...[
                _AttentionMedicationCard(
                  occurrence: item,
                  circleId: widget.circleId,
                ),
                if (item != widget.occurrences.last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    ),
  );
}

/// Renders the attention medication card element of today medication components.
class _AttentionMedicationCard extends StatelessWidget {
  const _AttentionMedicationCard({
    required this.occurrence,
    required this.circleId,
  });

  final DoseOccurrence occurrence;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(occurrence.doseValue),
        context.tr('medications.unit.${occurrence.doseUnit.name}'),
      ],
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
                      ),
                      child: Text(
                        '${occurrence.name} ${_strength(context, occurrence)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${formatMedicationDate(context, occurrence.scheduledOn)}'
                      ' · ${formatMedicationTime(context, occurrence.time)}',
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
  });
  final DoseOccurrence occurrence;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final now = riyadhNow();
    final status = medicationTimingState(occurrence, now);
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
            context.tr(switch (status) {
              DoseTimingState.due => 'today_dashboard.due_title',
              DoseTimingState.late => 'today_dashboard.late_title',
              _ => 'today_dashboard.next_dose',
            }),
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
          const SizedBox(height: AppSpacing.tight),
          _NextDoseInfo(occurrence: occurrence, circleId: circleId),
          const SizedBox(height: AppSpacing.lg),
          TodayDoseWindow(occurrence: occurrence, now: now),
          const SizedBox(height: AppSpacing.md),
          DoseRecordControls(
            occurrence: occurrence,
            layout: DoseControlsLayout.today,
          ),
        ],
      ),
    );
  }
}

/// Renders the next dose info element of today medication components.
class _NextDoseInfo extends StatelessWidget {
  const _NextDoseInfo({required this.occurrence, required this.circleId});

  final DoseOccurrence occurrence;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final strength = _strength(context, occurrence);
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(occurrence.doseValue),
        context.tr('medications.unit.${occurrence.doseUnit.name}'),
      ],
    );
    final formattedTime = formatMedicationTime(context, occurrence.time);
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
    required this.now,
    this.showThumbnail = false,
  });

  final DoseOccurrence occurrence;
  final String circleId;
  final DateTime now;
  final bool showThumbnail;

  @override
  Widget build(BuildContext context) {
    final status = medicationTimingState(occurrence, now);
    final isMissed = status == DoseTimingState.missed;
    final record = occurrence.record;
    final label = record != null
        ? context.tr(
            record.outcome == DoseOutcome.skipped
                ? 'today_dashboard.status.skipped'
                : occurrence.takenLate
                ? 'today_dashboard.status.taken_late'
                : 'today_dashboard.status.taken',
          )
        : context.tr('today_dashboard.status.${status!.name}');
    final isTaken = record?.outcome == DoseOutcome.taken;
    final isWaiting =
        status == DoseTimingState.due || status == DoseTimingState.late;
    final statusColor = isMissed
        ? context.tokens.errorText
        : isTaken
        ? context.tokens.successText
        : isWaiting
        ? context.tokens.warningText
        : context.tokens.textSecondary;
    final statusBackground = isMissed
        ? Theme.of(context).colorScheme.errorContainer
        : isTaken
        ? AppSemanticColors.selectedSurface
        : isWaiting
        ? AppSemanticColors.surfaceAttention
        : AppSemanticColors.surfaceContent;
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(occurrence.doseValue),
        context.tr('medications.unit.${occurrence.doseUnit.name}'),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isMissed
            ? Theme.of(context).colorScheme.errorContainer
            : AppSemanticColors.surfaceContent,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: isMissed ? Border.all(color: context.tokens.error) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              formatMedicationTime(context, occurrence.time),
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
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppSemanticColors.surfaceContent,
                        borderRadius: BorderRadius.circular(AppRadius.field),
                      ),
                      child: const Icon(TafaqodPhosphorIcons.pill),
                    )
                  : MedicationPhotoImage(bytes: bytes, width: 56, height: 56),
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
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!showThumbnail) ...[
                        const Icon(
                          TafaqodPhosphorIcons.pill,
                          size: 15,
                          color: AppSemanticColors.textSupporting,
                        ),
                        const SizedBox(width: AppSpacing.tight),
                      ],
                      Flexible(
                        child: Text(
                          '${occurrence.name} '
                          '${_strength(context, occurrence)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
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
          const SizedBox(width: AppSpacing.sm),
          CompactStatusBadge(
            text: label,
            background: statusBackground,
            foreground: statusColor,
          ),
        ],
      ),
    );
  }
}

String _strength(BuildContext context, DoseOccurrence occurrence) =>
    '${formatMedicationNumber(occurrence.strengthValue)} '
    '${context.tr('medications.strength_display.${occurrence.strengthUnit.name}')}';

/// Displays the medication period marks UI.
class MedicationPeriodMarks extends StatelessWidget {
  const MedicationPeriodMarks({
    super.key,
    required this.occurrences,
    required this.now,
  });

  final List<DoseOccurrence> occurrences;
  final DateTime now;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final occurrence in occurrences)
        _PeriodMark(occurrence: occurrence, now: now),
    ],
  );
}

/// Renders the period mark element of today medication components.
class _PeriodMark extends StatelessWidget {
  const _PeriodMark({required this.occurrence, required this.now});

  final DoseOccurrence occurrence;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final outcome = occurrence.record?.outcome;
    final missed =
        medicationTimingState(occurrence, now) == DoseTimingState.missed;
    final late = occurrence.takenLate;
    final color = outcome == DoseOutcome.taken
        ? late
              ? context.tokens.warningText
              : context.tokens.successText
        : missed
        ? context.tokens.errorText
        : context.tokens.textSecondary;
    final background = outcome == DoseOutcome.taken
        ? AppSemanticColors.selectedSurface
        : missed
        ? context.tokens.error.withValues(alpha: .08)
        : AppSemanticColors.surfaceContent;
    final icon = outcome == DoseOutcome.taken
        ? TafaqodPhosphorIcons.check
        : missed
        ? TafaqodPhosphorIcons.warning
        : TafaqodPhosphorIcons.minus;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: late ? Border.all(color: AppSemanticColors.accentWarm) : null,
        ),
        child: Icon(icon, size: 11, color: color),
      ),
    );
  }
}
