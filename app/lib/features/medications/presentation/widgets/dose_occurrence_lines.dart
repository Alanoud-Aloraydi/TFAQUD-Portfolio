import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/dose_occurrence.dart';
import 'package:app/features/medications/presentation/widgets/dose_strength_text.dart';
import 'package:app/features/medications/presentation/widgets/dose_timing_badge.dart';
import 'package:flutter/material.dart';

/// What a dose of the history says, as one sentence: the time with its
/// timing badge, then the medicine, its strength, the dose and the note.
/// «أُخذت» and «تأخير» are their own buttons, so they stay outside this.
class DoseOccurrenceLines extends StatelessWidget {
  const DoseOccurrenceLines({super.key, required this.occurrence});

  final DoseOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String dose = formatMedicationDose(
      context,
      occurrence.doseValue,
      occurrence.doseUnit,
    );
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                clockText(occurrence.time),
                style: text.titleMedium?.copyWith(
                  fontWeight: AppTextTheme.bold,
                  color: AppSemanticColors.textPrimary,
                ),
              ),
              const Spacer(),
              DoseTimingBadge(
                state: occurrence.timingState,
                scheduledOn: occurrence.scheduledOn,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(occurrence.name, style: text.titleMedium),
          Text(doseStrengthText(context, occurrence)),
          const SizedBox(height: AppSpacing.xs),
          Text(dose, style: text.bodySmall),
          if (occurrence.instructions case final String instructions)
            Text(instructions, style: text.bodySmall),
        ],
      ),
    );
  }
}
