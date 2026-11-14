import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// One schedule of a medicine in its opened details: the time in bold, the
/// dose as a badge at the end, and the days it repeats on under the time.
class MedicationScheduleLine extends StatelessWidget {
  const MedicationScheduleLine({super.key, required this.schedule});

  final MedicationSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final TextStyle? small = Theme.of(context).textTheme.labelMedium;
    return PlanFact(
      icon: AppIcons.clock,
      value: clockText(schedule.time),
      trailing: StatusBadge(
        text: formatMedicationDose(
          context,
          schedule.doseValue,
          schedule.doseUnit,
        ),
        tone: StatusTone.neutral,
        icon: AppIcons.pill,
      ),
      below: switch (schedule.repeat) {
        ScheduleRepeat.monthly => Text(
          formatMonthDays(context, schedule.monthDays),
          style: small,
        ),
        ScheduleRepeat.interval => Text(
          formatInterval(context, schedule.intervalDays ?? 1),
          style: small,
        ),
        ScheduleRepeat.weekly => WeekdayStrip(days: schedule.weekdays),
      },
    );
  }
}
