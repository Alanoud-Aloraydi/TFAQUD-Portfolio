import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar_weeks.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_condition_chips.dart';
import 'package:easy_localization/easy_localization.dart';
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
  final CalendarMonth month;
  final String circleId;

  @override
  State<MeasurementCalendar> createState() => _MeasurementCalendarState();
}

class _MeasurementCalendarState extends State<MeasurementCalendar> {
  int? _selectedDay;

  @override
  void didUpdateWidget(MeasurementCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.month != widget.month) {
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

/// The short names of the days over a Saturday-first calendar.
class MeasurementCalendarWeekdays extends StatelessWidget {
  const MeasurementCalendarWeekdays({super.key});

  static const List<int> _weekdays = <int>[6, 7, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (final int day in _weekdays)
        Expanded(
          child: Center(
            child: Text(
              context.tr('medications.weekday_short.$day'),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
        ),
    ],
  );
}
