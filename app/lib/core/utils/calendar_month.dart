import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/utils/hijri/hijri_date.dart';
import 'package:equatable/equatable.dart';

/// A month of the chosen calendar, as the Gregorian days it covers: a Hijri
/// month is 29 or 30 days that start mid Gregorian month. [year] and
/// [month] are the calendar's own; [first] is its first day at midnight.
/// Outside the Hijri table (before 1924) a Hijri month is Gregorian.
class CalendarMonth extends Equatable {
  const CalendarMonth._(
    this.calendar,
    this.year,
    this.month,
    this.first,
    this.days,
  );

  /// The month of [calendar] that holds [date].
  factory CalendarMonth.of(DateTime date, DateCalendar calendar) {
    final HijriDate? h = calendar == DateCalendar.hijri
        ? HijriDate.of(date)
        : null;
    if (h != null) {
      final DateTime first = DateTime(
        date.year,
        date.month,
        date.day - h.day + 1,
      );
      return CalendarMonth._(
        calendar,
        h.year,
        h.month,
        first,
        HijriDate.monthLength(h.year, h.month)!,
      );
    }
    return CalendarMonth._(
      DateCalendar.gregorian,
      date.year,
      date.month,
      DateTime(date.year, date.month),
      DateTime(date.year, date.month + 1, 0).day,
    );
  }

  final DateCalendar calendar;
  final int year;
  final int month;
  final DateTime first;
  final int days;

  /// Its last day.
  DateTime get last => dayAt(days);

  /// Its day [number] (1 is [first]); past [days] runs into the next month.
  DateTime dayAt(int number) =>
      DateTime(first.year, first.month, first.day + number - 1);

  /// [date]'s day in this month, 1 to [days]; null outside it.
  int? numberOf(DateTime date) {
    final int number =
        DateTime.utc(
          date.year,
          date.month,
          date.day,
        ).difference(DateTime.utc(first.year, first.month, first.day)).inDays +
        1;
    return number >= 1 && number <= days ? number : null;
  }

  bool holds(DateTime date) => numberOf(date) != null;

  /// The month [offset] months after this one (before it when negative).
  CalendarMonth shift(int offset) {
    CalendarMonth month = this;
    for (int i = 0; i < offset.abs(); i++) {
      month = CalendarMonth.of(
        offset > 0 ? month.dayAt(month.days + 1) : month.dayAt(0),
        calendar,
      );
    }
    return month;
  }

  bool isAfter(CalendarMonth other) => first.isAfter(other.first);

  @override
  List<Object?> get props => [calendar, year, month];
}
