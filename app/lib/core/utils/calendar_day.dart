import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/utils/hijri/hijri_date.dart';

/// A day as [DateCalendar] writes it: its own year, month and day.
typedef CalendarDay = ({int year, int month, int day});

/// The first and last days the Hijri table holds (1343 to 1500).
final DateTime hijriFirstDay = DateTime(1924, 8);
final DateTime hijriLastDay = DateTime(2077, 11, 16);

/// [date] as [calendar] writes it; a Hijri day outside the table is the
/// nearest end of it.
CalendarDay calendarDayOf(DateTime date, DateCalendar calendar) {
  if (calendar == DateCalendar.gregorian) {
    return (year: date.year, month: date.month, day: date.day);
  }
  final DateTime inside = date.isBefore(hijriFirstDay)
      ? hijriFirstDay
      : date.isAfter(hijriLastDay)
      ? hijriLastDay
      : date;
  final HijriDate h = HijriDate.of(inside)!;
  return (year: h.year, month: h.month, day: h.day);
}

/// The Gregorian day of [day] in [calendar], at midnight.
DateTime gregorianOf(CalendarDay day, DateCalendar calendar) =>
    calendar == DateCalendar.gregorian
    ? DateTime(day.year, day.month, day.day)
    : HijriDate(day.year, day.month, day.day).toGregorian()!;

/// The days of [calendar]'s [month] of [year].
int daysInCalendarMonth(int year, int month, DateCalendar calendar) =>
    calendar == DateCalendar.gregorian
    ? DateTime(year, month + 1, 0).day
    : HijriDate.monthLength(year, month)!;
