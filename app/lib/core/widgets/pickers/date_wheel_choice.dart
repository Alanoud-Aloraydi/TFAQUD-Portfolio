import 'package:app/core/localization/app_calendar.dart';
import 'package:app/core/localization/calendar_texts.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/calendar_day.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/core/widgets/pickers/date_wheel_row.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

/// The body of the date sheet. Every date in the app is picked with it, in
/// the calendar chosen in «حسابي» ([calendar] when given).
///
/// In a right-to-left language the first wheel is on the right: day, month,
/// year, as an Arabic date is read, in either calendar. Numbers use the
/// digits 0 to 9. With [offerCalendars] (a birth date) the person may turn
/// it to the other calendar, and the date in that one shows under it.
class DateWheelSheet extends StatefulWidget {
  const DateWheelSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.confirmLabel,
    this.calendar,
    this.offerCalendars = false,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? confirmLabel;
  final DateCalendar? calendar;
  final bool offerCalendars;

  @override
  State<DateWheelSheet> createState() => _DateWheelSheetState();
}

class _DateWheelSheetState extends State<DateWheelSheet> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (calendar != null) return;
    use(widget.calendar ?? CalendarScope.of(context), widget.initialDate);
  }

  @override
  Widget build(BuildContext context) => PickerSheetFrame(
    confirmLabel: widget.confirmLabel ?? context.tr('common.confirm'),
    onConfirm: () => Navigator.pop(context, date),
    child: DateWheelBody(
      ranges: ranges,
      day: chosen.day,
      date: date,
      offerCalendars: widget.offerCalendars,
      onSelected: select,
      onCalendar: (DateCalendar shown) => setState(() => use(shown, date)),
    ),
  );

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

/// The wheels of the date sheet; with [offerCalendars], the هجري | ميلادي
/// capsule above them and «يوافق …», the date in the other calendar,
/// under them.
class DateWheelBody extends StatelessWidget {
  const DateWheelBody({
    super.key,
    required this.ranges,
    required this.day,
    required this.date,
    required this.offerCalendars,
    required this.onSelected,
    required this.onCalendar,
  });

  final DateWheelRanges ranges;
  final int day;

  /// The chosen day, for the other calendar's line.
  final DateTime date;
  final bool offerCalendars;
  final void Function({int? year, int? month, int? day}) onSelected;
  final ValueChanged<DateCalendar> onCalendar;

  @override
  Widget build(BuildContext context) {
    final DateCalendar shown = ranges.calendar;
    final DateCalendar other = shown == DateCalendar.hijri
        ? DateCalendar.gregorian
        : DateCalendar.hijri;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (offerCalendars) ...<Widget>[
          GlassSegmentedControl<DateCalendar>(
            segments: <DateCalendar, String>{
              DateCalendar.hijri: context.tr('calendar.hijri'),
              DateCalendar.gregorian: context.tr('calendar.gregorian'),
            },
            selected: shown,
            onChanged: onCalendar,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // Built again on another calendar: its wheels start on the new day.
        DateWheelRow(
          key: ValueKey<DateCalendar>(shown),
          ranges: ranges,
          day: day,
          onSelected: onSelected,
        ),
        if (offerCalendars) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.tr(
              'calendar.matches',
              args: <String>[calendarDateWithEra(context, date, other)],
            ),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppSemanticColors.textSupporting),
          ),
        ],
      ],
    );
  }
}
