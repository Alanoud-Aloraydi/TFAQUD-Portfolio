import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/core/utils/hijri/hijri_date.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// [date]'s day, month name and year in [calendar] (the phone's choice
/// when left out, which [context] then follows): «9», «جمادى الآخرة»,
/// «1448» or «19», «نوفمبر», «2026». A day outside the Hijri table (before
/// 1924) stays Gregorian.
({int day, String month, int year}) calendarParts(
  BuildContext context,
  DateTime date, {
  DateCalendar? calendar,
}) {
  final bool hijri =
      (calendar ?? CalendarScope.of(context)) == DateCalendar.hijri;
  final HijriDate? h = hijri ? HijriDate.of(date) : null;
  if (h != null) {
    return (
      day: h.day,
      month: context.tr('calendar.hijri_months.${h.month}'),
      year: h.year,
    );
  }
  return (
    day: date.day,
    month: context.tr('circles.months.${date.month}'),
    year: date.year,
  );
}

/// «9 جمادى الآخرة 1448» or «19 نوفمبر 2026»; without [year], «9 جمادى
/// الآخرة»: the day first, then the month, then the year, in either
/// calendar.
String calendarDate(
  BuildContext context,
  DateTime date, {
  bool year = true,
  DateCalendar? calendar,
}) {
  final parts = calendarParts(context, date, calendar: calendar);
  return year
      ? '${parts.day} ${parts.month} ${parts.year}'
      : '${parts.day} ${parts.month}';
}

/// «جمادى الآخرة 1448» or «نوفمبر 2026»: [month] without its days.
String calendarMonthTitle(BuildContext context, CalendarMonth month) =>
    '${calendarParts(context, month.first, calendar: month.calendar).month} '
    '${month.year}';

/// «4 شوال 1373 هـ» or «5 يونيو 1954 م»: where both calendars show at once,
/// each says which it is.
String calendarDateWithEra(
  BuildContext context,
  DateTime date,
  DateCalendar calendar,
) =>
    '${calendarDate(context, date, calendar: calendar)} '
    '${context.tr('calendar.era.${calendar.name}')}';
