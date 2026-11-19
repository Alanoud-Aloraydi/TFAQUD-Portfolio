import 'package:app/core/l10n/app_calendar.dart';
import 'package:flutter/widgets.dart';

/// The calendar chosen in «حسابي», above every page: a date written under
/// it is written again, in place, when the choice changes, and nothing
/// else is rebuilt or read again.
class CalendarScope extends InheritedNotifier<ValueNotifier<DateCalendar>> {
  CalendarScope({super.key, required super.child})
    : super(notifier: AppCalendar.choice);

  /// The chosen calendar, depending on it; the phone's choice where no
  /// scope is above (a test without the app's scopes).
  static DateCalendar of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CalendarScope>()
          ?.notifier
          ?.value ??
      AppCalendar.choice.value;
}
