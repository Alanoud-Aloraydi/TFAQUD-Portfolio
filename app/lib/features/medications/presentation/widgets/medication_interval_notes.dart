import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Under the ruler: the day the counting starts from, and, for a schedule
/// that used to be monthly, the days of the month it kept.
class MedicationIntervalNotes extends StatelessWidget {
  const MedicationIntervalNotes({
    super.key,
    required this.formerMonthDays,
    this.startsOn,
  });

  final List<int> formerMonthDays;
  final DateTime? startsOn;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppSemanticColors.textSupporting);
    final DateTime? start = startsOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (start != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr(
              'medications.interval_from',
              args: <String>[formatMedicationDate(context, start)],
            ),
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
        if (formerMonthDays.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr(
              'medications.was_monthly',
              args: <String>[formatMonthDays(context, formerMonthDays)],
            ),
            textAlign: TextAlign.center,
            style: style,
          ),
        ],
      ],
    );
  }
}
