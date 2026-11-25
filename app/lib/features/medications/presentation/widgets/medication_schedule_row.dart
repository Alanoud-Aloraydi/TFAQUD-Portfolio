import 'package:app/core/localization/arabic_names.dart';
import 'package:app/core/localization/medication_format.dart';
import 'package:app/core/localization/weekdays_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/fact_pill.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// One dose time in the card, in soft pills on one line: «8:00 ص»،
/// «1 حبة»، «كل يومين»; the note written for it under them.
class MedicationScheduleRow extends StatelessWidget {
  const MedicationScheduleRow({super.key, required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final String? note = schedule.instructions;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inset,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: <Widget>[
                for (final String fact in <String>[
                  clockText(schedule.time),
                  formatMedicationDose(
                    context,
                    schedule.doseValue,
                    schedule.doseUnit,
                  ),
                  scheduleDaysText(context, schedule),
                ])
                  if (fact.isNotEmpty) FactPill(fact),
              ],
            ),
            if (note != null && note.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppSpacing.xs),
              Text(
                note,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: context.tokens.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Which days a schedule repeats on, in its own way of repeating: the days
/// of the month, every so many days, or the days of the week.
String scheduleDaysText(BuildContext context, MedicationSchedule schedule) =>
    switch (schedule.repeat) {
      ScheduleRepeat.monthly => formatMonthDays(context, schedule.monthDays),
      ScheduleRepeat.interval => formatInterval(
        context,
        schedule.intervalDays ?? 1,
      ),
      ScheduleRepeat.weekly => formatWeekdays(context, schedule.weekdays),
    };
