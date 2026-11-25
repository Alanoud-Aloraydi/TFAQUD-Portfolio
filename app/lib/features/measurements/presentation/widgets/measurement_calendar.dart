import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/widgets/patient_clock_scope.dart';
import 'package:app/features/measurements/domain/entities/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/chart_scale.dart';
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

/// The weeks of [month], Saturday first, each day with its readings
/// [byDay]; [onSelect] with the day tapped.
List<Widget> measurementCalendarWeeks({
  required CalendarMonth month,
  required Map<int, List<MeasurementReading>> byDay,
  required int? selectedDay,
  required ValueChanged<int> onSelect,
}) {
  final int days = month.days;
  final int lead = (month.first.weekday + 1) % 7;
  return <Widget>[
    for (int row = 0; row < ((lead + days) / 7).ceil(); row++)
      MeasurementCalendarWeek(
        firstDay: row * 7 - lead + 1,
        days: days,
        month: month,
        byDay: byDay,
        selectedDay: selectedDay,
        onSelect: onSelect,
      ),
  ];
}

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
  final CalendarMonth month;
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
      isToday: DateUtils.isSameDay(month.dayAt(day), today),
      onTap: () => onSelect(day),
    );
  }
}

/// One day of the month calendar: its number, a dot when it has readings
/// (amber when any is outside the target), a frame when selected or today.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.count,
    required this.outside,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final int day;
  final int count;
  final bool outside;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: spoken('$day، $count'),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: Container(
          height: AppSizes.touch,
          decoration: BoxDecoration(
            color: selected
                ? AppSemanticColors.selectedSurface
                : outside
                ? AppSemanticColors.surfaceAttention
                : AppSemanticColors.surfaceContent,
            borderRadius: BorderRadius.circular(AppRadius.s),
            border: Border.all(
              color: selected || isToday
                  ? AppSemanticColors.textPrimary
                  : AppSemanticColors.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('$day', style: Theme.of(context).textTheme.labelSmall),
              if (count > 0) CalendarDayDot(outside: outside),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dot under a calendar day that has readings: amber when any of them
/// is outside the target, green when all are inside.
class CalendarDayDot extends StatelessWidget {
  const CalendarDayDot({super.key, required this.outside});

  final bool outside;

  static const double _size = 5;

  @override
  Widget build(BuildContext context) => Container(
    width: _size,
    height: _size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: outside
          ? AppSemanticColors.statusWarning
          : AppSemanticColors.statusSuccess,
    ),
  );
}
