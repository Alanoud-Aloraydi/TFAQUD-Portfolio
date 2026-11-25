import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_history_entry.dart';
import 'package:app/features/medications/presentation/widgets/dose_occurrence_card.dart';
import 'package:app/features/medications/presentation/widgets/extra_dose_card.dart';
import 'package:flutter/material.dart';

/// [entries], newest first, under the date of their day: the doses of the
/// dose times and the extra doses, each in the same card.
class DoseHistoryDays extends StatelessWidget {
  const DoseHistoryDays({
    super.key,
    required this.entries,
    required this.circleId,
  });

  final List<DoseHistoryEntry> entries;

  /// Needed to show who recorded each dose.
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<DoseHistoryEntry>> days =
        <DateTime, List<DoseHistoryEntry>>{};
    for (final DoseHistoryEntry item in entries) {
      final DateTime day = DateUtils.dateOnly(item.day);
      days.putIfAbsent(day, () => <DoseHistoryEntry>[]).add(item);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final MapEntry<DateTime, List<DoseHistoryEntry>> day
            in days.entries) ...<Widget>[
          Text(
            formatMedicationDate(context, day.key),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final DoseHistoryEntry item in day.value) ...<Widget>[
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppSemanticColors.surfaceContent,
                border: Border.all(color: AppSemanticColors.borderSubtle),
                borderRadius: BorderRadius.circular(AppRadius.m),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: switch (item) {
                  ScheduledDoseEntry(:final occurrence) => DoseOccurrenceCard(
                    occurrence: occurrence,
                    circleId: circleId,
                  ),
                  ExtraDoseEntry() => ExtraDoseCard(
                    entry: item,
                    circleId: circleId,
                  ),
                },
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
