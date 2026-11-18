import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar_selection.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar_weeks.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar_weekdays.dart';
import 'package:flutter/material.dart';

/// Compact Saturday-first calendar with the readings of the selected day
/// shown below it.
class MeasurementCalendar extends StatefulWidget {
  const MeasurementCalendar({
    super.key,
    required this.readings,
    required this.month,
    required this.circleId,
  });

  final List<MeasurementReading> readings;
  final DateTime month;
  final String circleId;

  @override
  State<MeasurementCalendar> createState() => _MeasurementCalendarState();
}

class _MeasurementCalendarState extends State<MeasurementCalendar> {
  int? _selectedDay;

  @override
  void didUpdateWidget(MeasurementCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month.year != widget.month.year ||
        oldWidget.month.month != widget.month.month) {
      _selectedDay = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, List<MeasurementReading>> byDay = readingsByDay(
      widget.readings,
      widget.month,
      PatientClockScope.of(context),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MeasurementCalendarWeekdays(),
        const SizedBox(height: AppSpacing.sm),
        ...measurementCalendarWeeks(
          month: widget.month,
          byDay: byDay,
          selectedDay: _selectedDay,
          onSelect: (day) => setState(() => _selectedDay = day),
        ),
        if (_selectedDay case final int day)
          ...measurementCalendarSelection(
            context,
            day: day,
            month: widget.month,
            readings: byDay[day] ?? const [],
            circleId: widget.circleId,
          ),
      ],
    );
  }
}
