import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/l10n/weekdays_text.dart';
import 'package:app/features/medications/domain/entities/medication_schedule.dart';
import 'package:flutter/widgets.dart';

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
