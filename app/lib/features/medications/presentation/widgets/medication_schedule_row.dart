import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/weekdays_text.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// One dose time in the card: the clock, «8:00 ص · 1 قرص», and under it
/// the days and the note, with the rows' 16 side padding.
class MedicationScheduleRow extends StatelessWidget {
  const MedicationScheduleRow({super.key, required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final time = clockText(schedule.time);
    final days = switch (schedule.repeat) {
      ScheduleRepeat.monthly => formatMonthDays(context, schedule.monthDays),
      ScheduleRepeat.interval => formatInterval(
        context,
        schedule.intervalDays ?? 1,
      ),
      ScheduleRepeat.weekly => formatWeekdays(context, schedule.weekdays),
    };
    final dose = formatMedicationDose(
      context,
      schedule.doseValue,
      schedule.doseUnit,
    );
    final details = [
      days,
      schedule.instructions,
    ].whereType<String>().where((value) => value.isNotEmpty).join('\n');
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.inset,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AppIcons.clock,
              size: AppSizes.iconSmall,
              color: context.tokens.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$time · $dose', style: text.bodyLarge),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      details,
                      style: text.bodySmall?.copyWith(
                        color: context.tokens.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
