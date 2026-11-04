import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
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
    this.timingState,
  });

  final DoseOccurrence occurrence;
  final bool showDate;
  final bool showControls;
  final DoseTimingState? timingState;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              DoseRecordControls(occurrence: occurrence),
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
    final value = formatMedicationTime(context, occurrence.time);
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
            Text(value, style: Theme.of(context).textTheme.labelMedium),
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
    final icon = switch (state!) {
      DoseTimingState.upcoming => AppIcons.clock,
      DoseTimingState.due => AppIcons.alarm,
      DoseTimingState.late => AppIcons.warning,
      DoseTimingState.missed => AppIcons.calendarX,
    };
    final label = context.tr('medications.timing.${state!.name}');
    final tokens = context.tokens;
    final (Color icon, Color text) colors = switch (state!) {
      DoseTimingState.upcoming => (tokens.textSecondary, tokens.textSecondary),
      DoseTimingState.due => (
        AppSemanticColors.textPrimary,
        AppSemanticColors.textPrimary,
      ),
      // Timing needs attention, but is not a medical error or proof of omission.
      DoseTimingState.late ||
      DoseTimingState.missed => (tokens.warning, tokens.warningText),
    };
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSmall, color: colors.$1),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: colors.$2),
          ),
        ],
      ),
    );
  }
}

/// Renders the dose details element of dose occurrence card.
class _DoseDetails extends StatelessWidget {
  const _DoseDetails({required this.occurrence});

  final DoseOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final dose = context.tr(
      'medications.dose',
      args: [
        formatMedicationNumber(occurrence.doseValue),
        context.tr('medications.unit.${occurrence.doseUnit.name}'),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(occurrence.name, style: Theme.of(context).textTheme.titleLarge),
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
