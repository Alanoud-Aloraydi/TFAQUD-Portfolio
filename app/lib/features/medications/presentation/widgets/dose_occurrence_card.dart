import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_record_controls.dart';
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.lg),
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
    final value = DateFormat.jm(context.locale.toString())
        .format(DateTime.parse('2000-01-01T${occurrence.time}'));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.field),
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
                DateFormat.Md(context.locale.toString())
                    .format(occurrence.scheduledOn),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            Text(value, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
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
        occurrence.doseValue.toString().replaceFirst(RegExp(r'\.0$'), ''),
        context.tr('medications.unit.${occurrence.doseUnit.name}'),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(occurrence.name, style: Theme.of(context).textTheme.titleLarge),
        if (occurrence.strength case final strength?) Text(strength),
        const SizedBox(height: AppSpacing.xs),
        Text(dose, style: Theme.of(context).textTheme.bodySmall),
        if (occurrence.instructions case final instructions?)
          Text(instructions, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
