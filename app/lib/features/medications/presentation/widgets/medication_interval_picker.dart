import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/pickers/ruler_picker.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:app/features/medications/presentation/cubit/medication_schedule_form_data.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «نذكرك كل» over the number of days, large, and the ruler under it:
/// 1 «يوم», 2 «يومين», 3 to 10 «أيام», then «يوم».
class MedicationIntervalPicker extends StatelessWidget {
  const MedicationIntervalPicker({
    super.key,
    required this.data,
    required this.onChanged,
    this.startsOn,
  });

  final ScheduleFormData data;
  final VoidCallback onChanged;
  final DateTime? startsOn;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    String days(int count) => arabicCount(context, ArabicCount.days, count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                context.tr('medications.interval_title'),
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSupporting,
                ),
              ),
              Text(
                days(data.intervalDays),
                textAlign: TextAlign.center,
                style: text.headlineMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        RulerPicker(
          min: 1,
          max: maxIntervalDays,
          value: data.intervalDays,
          semanticLabel: context.tr('medications.interval_days'),
          valueLabel: days,
          onChanged: (int value) {
            data.intervalDays = value;
            onChanged();
          },
        ),
        MedicationIntervalNotes(
          startsOn: startsOn,
          formerMonthDays: data.formerMonthDays,
        ),
      ],
    );
  }
}

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
