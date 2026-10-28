import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
import 'package:app/features/medications/presentation/medication_format.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DoseOccurrenceCard extends StatelessWidget {
  const DoseOccurrenceCard({
    super.key,
    required this.occurrence,
    this.showDate = false,
  });

  final DoseOccurrence occurrence;
  final bool showDate;

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
                _TimeBadge(occurrence: occurrence, showDate: showDate),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _DoseDetails(occurrence: occurrence)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DoseRecordControls(occurrence: occurrence),
          ],
        ),
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.occurrence, required this.showDate});

  final DoseOccurrence occurrence;
  final bool showDate;

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
            _TimingState(state: occurrence.timingState),
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
      DoseTimingState.upcoming => Icons.schedule_outlined,
      DoseTimingState.due => Icons.notifications_active_outlined,
      DoseTimingState.late => Icons.warning_amber_rounded,
      DoseTimingState.missed => Icons.event_busy_outlined,
    };
    final label = context.tr('medications.timing.${state!.name}');
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      label: label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

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
          '${occurrence.strengthUnit.apiValue}',
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(dose, style: Theme.of(context).textTheme.bodySmall),
        if (occurrence.instructions case final instructions?)
          Text(instructions, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
