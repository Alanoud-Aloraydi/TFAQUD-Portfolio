import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/widgets/calendar_scope.dart';
import 'package:app/core/widgets/pickers/date_wheel_body.dart';
import 'package:app/core/widgets/pickers/date_wheel_choice.dart';
import 'package:app/core/widgets/pickers/picker_sheet_frame.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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

class _DateWheelSheetState extends State<DateWheelSheet> with DateWheelChoice {
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
}
