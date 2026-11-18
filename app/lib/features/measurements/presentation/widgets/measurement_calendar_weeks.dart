import 'package:app/features/measurements/domain/measurement_reading.dart';
import 'package:app/features/measurements/presentation/widgets/measurement_calendar_week.dart';
import 'package:flutter/material.dart';

/// The weeks of [month], Saturday first, each day with its readings
/// [byDay]; [onSelect] with the day tapped.
List<Widget> measurementCalendarWeeks({
  required DateTime month,
  required Map<int, List<MeasurementReading>> byDay,
  required int? selectedDay,
  required ValueChanged<int> onSelect,
}) {
  final int days = DateUtils.getDaysInMonth(month.year, month.month);
  final int lead = (month.weekday + 1) % 7;
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
