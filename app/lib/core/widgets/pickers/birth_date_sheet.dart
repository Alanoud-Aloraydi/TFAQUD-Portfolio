import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/utils/birth_date_rules.dart';
import 'package:app/core/utils/schedule_day.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Opens the birth date sheet. Returns the confirmed date, or null when the
/// sheet is closed without confirming. [today] is only for tests.
///
/// It is the app's one date picker (the iOS wheel of [DateWheelSheet]),
/// limited to what [BirthDateRules] allows: from 1900 up to today, or up
/// to [youngestAge] years back (15 for a person's own: an account holder).
Future<DateTime?> showBirthDateSheet(
  BuildContext context, {
  DateTime? selected,
  DateTime? today,
  int youngestAge = 0,
}) {
  return showGlassSheet<DateTime>(
    context,
    title: context.tr('circles.birth_date'),
    builder: (BuildContext context) => BirthDateSheet(
      selected: selected,
      // The newest day anywhere on Earth: a birth date may be today
      // where the person lives, whatever this phone's zone. The server
      // checks a patient's again in the patient's own zone.
      today: today ?? latestToday(),
      youngestAge: youngestAge,
    ),
  );
}

/// The date as a field shows it, "12 مارس 1964" (or Hijri, as chosen in
/// «حسابي»): the day and the year are written with the digits 0 to 9, like
/// every number of the app.
String formatBirthDate(BuildContext context, DateTime date) =>
    calendarDate(context, date);

/// The birth date wheel. With no date chosen yet it opens about 40 years
/// back, on the first of January.
class BirthDateSheet extends StatelessWidget {
  const BirthDateSheet({
    super.key,
    this.selected,
    required this.today,
    this.youngestAge = 0,
  });

  final DateTime? selected;
  final DateTime today;

  /// The youngest the person may be: the newest day is that many years
  /// back (0: today).
  final int youngestAge;

  @override
  Widget build(BuildContext context) {
    final DateTime last = BirthDateRules.yearsBefore(
      DateUtils.dateOnly(today),
      youngestAge,
    );
    return DateWheelSheet(
      confirmLabel: context.tr('circles.date_confirm'),
      initialDate: BirthDateRules.clamp(
        selected?.year ?? today.year - 40,
        selected?.month ?? 1,
        selected?.day ?? 1,
        last,
      ),
      firstDate: DateTime(BirthDateRules.firstYear),
      lastDate: last,
      // A birth date may be known in either calendar: both are offered.
      offerCalendars: true,
    );
  }
}

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
