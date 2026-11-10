import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/compact_status_badge.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Displays the dose occurrence card UI.
class DoseOccurrenceCard extends StatelessWidget {
  const DoseOccurrenceCard({
    super.key,
    required this.occurrence,
    this.showDate = false,
    this.showControls = true,
    this.historyLayout = false,
    this.timingState,
    this.circleId,
  });

  final DoseOccurrence occurrence;
  final bool showDate;
  final bool showControls;
  final bool historyLayout;
  final DoseTimingState? timingState;

  /// Needed to show who recorded it; null hides that line.
  final String? circleId;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (historyLayout) ...[
              Row(
                children: [
                  Text(
                    clockText(occurrence.time),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: AppTextTheme.bold,
                      color: AppSemanticColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  _TimingState(state: timingState ?? occurrence.timingState),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _DoseDetails(occurrence: occurrence, compact: true),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TimeBadge(
                    occurrence: occurrence,
                    showDate: showDate,
                    timingState: timingState ?? occurrence.timingState,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _DoseDetails(occurrence: occurrence)),
                ],
              ),
            if (showControls || occurrence.record != null) ...[
              const SizedBox(height: AppSpacing.md),
              DoseRecordControls(occurrence: occurrence, circleId: circleId),
            ],
          ],
        ),
      ),
    );
  }
}

/// Renders the time badge element of dose occurrence card.
class _TimeBadge extends StatelessWidget {
  const _TimeBadge({
    required this.occurrence,
    required this.showDate,
    required this.timingState,
  });

  final DoseOccurrence occurrence;
  final bool showDate;
  final DoseTimingState? timingState;

  @override
  Widget build(BuildContext context) {
    final value = clockText(occurrence.time);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(
          end: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          children: [
            if (showDate)
              Text(
                formatMedicationDate(context, occurrence.scheduledOn),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTextTheme.bold,
                color: AppSemanticColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _TimingState(state: timingState),
          ],
        ),
      ),
    );
  }
}

class _TimingState extends StatelessWidget {
  const _TimingState({required this.state});

  final DoseTimingState? state;

  @override
  Widget build(BuildContext context) {
    if (state == null) return const SizedBox.shrink();
    final label = context.tr('medications.timing.${state!.name}');
    final tokens = context.tokens;
    final (Color background, Color foreground) colors = switch (state!) {
      DoseTimingState.upcoming => (
        AppSemanticColors.surfaceContent,
        tokens.textSecondary,
      ),
      DoseTimingState.due => (
        AppSemanticColors.surfaceContent,
        AppSemanticColors.textPrimary,
      ),
      // Timing needs attention, but is not a medical error or proof of omission.
      DoseTimingState.late || DoseTimingState.missed => (
        AppSemanticColors.surfaceAttention,
        tokens.warningText,
      ),
    };
    return CompactStatusBadge(
      text: label,
      background: colors.$1,
      foreground: colors.$2,
    );
  }
}

/// Renders the dose details element of dose occurrence card.
class _DoseDetails extends StatelessWidget {
  const _DoseDetails({required this.occurrence, this.compact = false});

  final DoseOccurrence occurrence;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          occurrence.name,
          style: compact
              ? Theme.of(context).textTheme.titleMedium
              : Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          '${formatMedicationNumber(occurrence.strengthValue)} '
          '${context.tr('medications.strength_display.${occurrence.strengthUnit.name}')}',
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(dose, style: Theme.of(context).textTheme.bodySmall),
        if (occurrence.instructions case final instructions?)
          Text(instructions, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
