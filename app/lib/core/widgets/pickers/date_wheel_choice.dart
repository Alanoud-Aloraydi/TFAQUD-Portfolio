import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/utils/calendar_day.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/pickers/date_wheel_row.dart';
import 'package:app/core/widgets/pickers/date_wheel_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

export 'package:app/core/widgets/pickers/date_wheel_sheet.dart';

/// What a [DateWheelSheet] holds: the calendar shown and the day chosen in
/// its own numbers, kept inside the sheet's range.
mixin DateWheelChoice on State<DateWheelSheet> {
  DateCalendar? calendar;
  late CalendarDay chosen;

  DateCalendar get _shown => calendar!;

  // The Hijri table holds 1924 to 2077: a range past it ends there.
  DateTime get _first =>
      _shown == DateCalendar.hijri && widget.firstDate.isBefore(hijriFirstDay)
      ? hijriFirstDay
      : widget.firstDate;
  DateTime get _last =>
      _shown == DateCalendar.hijri && widget.lastDate.isAfter(hijriLastDay)
      ? hijriLastDay
      : widget.lastDate;

  /// Shows [shown], on [day] or the nearest day inside the range.
  void use(DateCalendar shown, DateTime day) {
    calendar = shown;
    final DateTime inside = day.isBefore(_first)
        ? _first
        : day.isAfter(_last)
        ? _last
        : day;
    chosen = calendarDayOf(inside, shown);
  }

  /// The chosen day, as the app keeps it.
  DateTime get date => gregorianOf(chosen, _shown);

  DateWheelRanges get ranges => DateWheelRanges(
    first: calendarDayOf(_first, _shown),
    last: calendarDayOf(_last, _shown),
    year: chosen.year,
    month: chosen.month,
    calendar: _shown,
  );

  /// Changing the year or the month can leave the day (or the month) out of
  /// range, such as 30 in a 29-day month; it moves back to the nearest one.
  void select({int? year, int? month, int? day}) => setState(() {
    chosen = (
      year: year ?? chosen.year,
      month: month ?? chosen.month,
      day: day ?? chosen.day,
    );
    final List<int> months = ranges.months;
    chosen = (
      year: chosen.year,
      month: chosen.month.clamp(months.first, months.last),
      day: chosen.day,
    );
    final List<int> days = ranges.days;
    chosen = (
      year: chosen.year,
      month: chosen.month,
      day: chosen.day.clamp(days.first, days.last),
    );
  });
}

/// Opens the app's one date picker, in a glass sheet: an iOS wheel of day,
/// month and year with one selection band across the row. Returns the confirmed date, or null
/// when the sheet is closed without confirming.
///
/// [confirmLabel] defaults to «تأكيد».
Future<DateTime?> showTafaqodDateSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? confirmLabel,
}) => showGlassSheet<DateTime>(
  context,
  title: title,
  builder: (_) => DateWheelSheet(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    confirmLabel: confirmLabel,
  ),
);
