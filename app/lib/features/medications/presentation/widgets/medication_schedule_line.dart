import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/display/weekday_strip.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/material.dart';

/// One schedule of a medicine: its time and dose, and the days it repeats on.
/// On a narrow card the days drop under the time and dose.
class MedicationScheduleLine extends StatelessWidget {
  const MedicationScheduleLine({super.key, required this.schedule});

  final MedicationSchedule schedule;

  /// Below this width the days no longer fit beside the time and dose.
  static const double _wideWidth = 290;
  static const double _timeWidth = 60;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget time = Text(clockText(schedule.time), style: text.titleSmall);
    final Widget dose = Text(
      formatMedicationDose(context, schedule.doseValue, schedule.doseUnit),
    );
    final Widget days = switch (schedule.repeat) {
      ScheduleRepeat.monthly => Text(
        formatMonthDays(context, schedule.monthDays),
        style: text.labelSmall,
      ),
      ScheduleRepeat.interval => Text(
        formatInterval(context, schedule.intervalDays ?? 1),
        style: text.labelSmall,
      ),
      ScheduleRepeat.weekly => WeekdayStrip(days: schedule.weekdays),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= _wideWidth
            ? Row(
                children: <Widget>[
                  SizedBox(width: _timeWidth, child: time),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: dose),
                  // Many days of the month wrap instead of overflowing.
                  if (schedule.repeat == ScheduleRepeat.weekly)
                    days
                  else
                    Flexible(child: days),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      time,
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: dose),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  days,
                ],
              ),
      ),
    );
  }
}
