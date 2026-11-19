import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/history_filter.dart';

/// A history's [items] under a filter: what its menu offers (the months of
/// [calendar] and who recorded) and what shows. The filter keeps only what
/// the items still have ([HistoryFilter.within]).
class HistoryView<T> {
  HistoryView(
    List<T> items,
    HistoryFilter wanted, {
    required DateTime Function(T item) dayOf,
    required (String?, String?) Function(T item) byOf,
    DateCalendar calendar = DateCalendar.gregorian,
  }) : months = HistoryFilter.monthsOf(items.map(dayOf), calendar: calendar),
       people = HistoryFilter.peopleOf(items.map(byOf)) {
    filter = wanted.within(months, people);
    shown = <T>[
      for (final T item in items)
        if (filter.shows(dayOf(item), byOf(item), calendar: calendar)) item,
    ];
  }

  /// The months that have records, newest first.
  final List<DateTime> months;

  /// Who recorded, key to name.
  final Map<String, String> people;

  /// The filter asked for, less what the items no longer have.
  late final HistoryFilter filter;

  /// The items that show under [filter].
  late final List<T> shown;
}
