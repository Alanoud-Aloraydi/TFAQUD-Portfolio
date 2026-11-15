import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:flutter/material.dart';

/// [occurrences], newest first, under the date of their day.
class DoseHistoryDays extends StatelessWidget {
  const DoseHistoryDays({
    super.key,
    required this.occurrences,
    required this.circleId,
  });

  final List<DoseOccurrence> occurrences;

  /// Needed to show who recorded each dose.
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<DoseOccurrence>> days =
        <DateTime, List<DoseOccurrence>>{};
    for (final DoseOccurrence item in occurrences) {
      final DateTime day = DateUtils.dateOnly(item.scheduledOn);
      days.putIfAbsent(day, () => <DoseOccurrence>[]).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<DateTime, List<DoseOccurrence>> day
            in days.entries) ...<Widget>[
          Text(
            formatMedicationDate(context, day.key),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final DoseOccurrence item in day.value) ...<Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: DoseOccurrenceCard(occurrence: item, circleId: circleId),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
