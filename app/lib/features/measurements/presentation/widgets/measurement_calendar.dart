import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/empty_state_note.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/measurement.dart';
import 'package:app/features/measurements/presentation/widgets/calendar_day_cell.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_reading_tile.dart';
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
  final DateTime month;
  final String circleId;

  @override
  State<MeasurementCalendar> createState() => _MeasurementCalendarState();
}

class _MeasurementCalendarState extends State<MeasurementCalendar> {
  static const List<int> _weekdays = <int>[6, 7, 1, 2, 3, 4, 5];

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
    final int days = DateUtils.getDaysInMonth(
      widget.month.year,
      widget.month.month,
    );
    final int lead = (widget.month.weekday + 1) % 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _weekdayRow(context),
        const SizedBox(height: AppSpacing.sm),
        for (int row = 0; row < ((lead + days) / 7).ceil(); row++)
          _week(context, row, lead, days, byDay),
        if (_selectedDay != null)
          ..._selection(context, byDay[_selectedDay] ?? const []),
      ],
    );
  }

  Widget _weekdayRow(BuildContext context) => Row(
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

  Widget _week(
    BuildContext context,
    int row,
    int lead,
    int days,
    Map<int, List<MeasurementReading>> byDay,
  ) {
    final DateTime today = PatientClockScope.of(context).today();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          for (int column = 0; column < 7; column++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _cell(row * 7 + column - lead + 1, days, today, byDay),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(
    int day,
    int days,
    DateTime today,
    Map<int, List<MeasurementReading>> byDay,
  ) {
    if (day < 1 || day > days) return const SizedBox(height: AppSizes.touch);
    final List<MeasurementReading> values = byDay[day] ?? const [];
    return CalendarDayCell(
      day: day,
      count: values.length,
      outside: values.any((r) => r.outsideTarget == true),
      selected: _selectedDay == day,
      isToday: DateUtils.isSameDay(
        DateTime(widget.month.year, widget.month.month, day),
        today,
      ),
      onTap: () => setState(() => _selectedDay = day),
    );
  }

  List<Widget> _selection(
    BuildContext context,
    List<MeasurementReading> readings,
  ) => <Widget>[
    const SizedBox(height: AppSpacing.sm),
    Text(
      '$_selectedDay ${context.tr('circles.months.${widget.month.month}')}',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    if (readings.isEmpty)
      EmptyStateNote(context.tr('measurements.no_readings'))
    else
      for (final MeasurementReading reading in readings) ...<Widget>[
        MeasurementReadingTile(reading: reading, circleId: widget.circleId),
        const SizedBox(height: AppSpacing.xs),
      ],
  ];
}
