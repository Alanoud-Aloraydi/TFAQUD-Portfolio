import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/calendar_day_cell.dart';
import 'package:flutter/material.dart';

/// One week of a month's calendar, from [firstDay] (below 1 or past [days]
/// is an empty cell): each day with its count of readings [byDay].
class MeasurementCalendarWeek extends StatelessWidget {
  const MeasurementCalendarWeek({
    super.key,
    required this.firstDay,
    required this.days,
    required this.month,
    required this.byDay,
    required this.selectedDay,
    required this.onSelect,
  });

  final int firstDay;
  final int days;
  final DateTime month;
  final Map<int, List<MeasurementReading>> byDay;
  final int? selectedDay;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final DateTime today = PatientClockScope.of(context).today();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          for (int column = 0; column < 7; column++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _cell(firstDay + column, today),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(int day, DateTime today) {
    if (day < 1 || day > days) return const SizedBox(height: AppSizes.touch);
    final List<MeasurementReading> values = byDay[day] ?? const [];
    return CalendarDayCell(
      day: day,
      count: values.length,
      outside: values.any((r) => r.outsideTarget == true),
      selected: selectedDay == day,
      isToday: DateUtils.isSameDay(
        DateTime(month.year, month.month, day),
        today,
      ),
      onTap: () => onSelect(day),
    );
  }
}
