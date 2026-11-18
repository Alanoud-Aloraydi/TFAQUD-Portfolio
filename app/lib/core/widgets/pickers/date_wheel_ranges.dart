import 'package:flutter/material.dart';

/// The years, months and days a date wheel offers between [firstDate] and
/// [lastDate], for the chosen [year] and [month].
class DateWheelRanges {
  const DateWheelRanges({
    required this.firstDate,
    required this.lastDate,
    required this.year,
    required this.month,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final int year;
  final int month;

  List<int> get years => <int>[
    for (int year = firstDate.year; year <= lastDate.year; year++) year,
  ];

  List<int> get months {
    final int first = year == firstDate.year ? firstDate.month : 1;
    final int last = year == lastDate.year ? lastDate.month : 12;
    return <int>[for (int month = first; month <= last; month++) month];
  }

  List<int> get days {
    final int first = year == firstDate.year && month == firstDate.month
        ? firstDate.day
        : 1;
    final int last = year == lastDate.year && month == lastDate.month
        ? lastDate.day
        : DateUtils.getDaysInMonth(year, month);
    return <int>[for (int day = first; day <= last; day++) day];
  }
}
