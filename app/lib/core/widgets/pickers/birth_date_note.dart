import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/l10n/calendar_texts.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// «يوافق 5 يونيو 1954 م»: under a birth date field, the date in the other
/// calendar, so both are always in sight; null with no date.
String? birthDateNote(BuildContext context, DateTime? date) {
  if (date == null) return null;
  final DateCalendar other = CalendarScope.of(context) == DateCalendar.hijri
      ? DateCalendar.gregorian
      : DateCalendar.hijri;
  return context.tr(
    'calendar.matches',
    args: <String>[calendarDateWithEra(context, date, other)],
  );
}
