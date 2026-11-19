import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/calendar_day.dart';

/// The years, months and days a date wheel offers between [first] and
/// [last], for the chosen [year] and [month], all in [calendar]'s own
/// numbers.
class DateWheelRanges {
  const DateWheelRanges({
    required this.first,
    required this.last,
    required this.year,
    required this.month,
    required this.calendar,
  });

  final CalendarDay first;
  final CalendarDay last;
  final int year;
  final int month;
  final DateCalendar calendar;

  List<int> get years => <int>[
    for (int year = first.year; year <= last.year; year++) year,
  ];

  List<int> get months {
    final int from = year == first.year ? first.month : 1;
    final int to = year == last.year ? last.month : 12;
    return <int>[for (int month = from; month <= to; month++) month];
  }

  List<int> get days {
    final int from = year == first.year && month == first.month ? first.day : 1;
    final int to = year == last.year && month == last.month
        ? last.day
        : daysInCalendarMonth(year, month, calendar);
    return <int>[for (int day = from; day <= to; day++) day];
  }
}
