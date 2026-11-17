import 'package:app/core/utils/history_filter.dart';

/// A history's [items] under a filter: what its menu offers (the months,
/// who recorded, the kinds) and what shows. The filter keeps only what
/// the items still have ([HistoryFilter.within]).
class HistoryView<T> {
  HistoryView(
    List<T> items,
    HistoryFilter wanted, {
    required DateTime Function(T item) dayOf,
    required (String?, String?) Function(T item) byOf,
    Map<String, String> kinds = const <String, String>{},
    String Function(T item)? kindOf,
  }) : months = HistoryFilter.monthsOf(items.map(dayOf)),
       people = HistoryFilter.peopleOf(items.map(byOf)),
       kinds = <String, String>{
         for (final MapEntry<String, String> kind in kinds.entries)
           if (items.any((T item) => kindOf?.call(item) == kind.key))
             kind.key: kind.value,
       } {
    filter = wanted.within(months, people, this.kinds);
    shown = <T>[
      for (final T item in items)
        if (filter.shows(dayOf(item), byOf(item), kindOf?.call(item))) item,
    ];
  }

  /// The months that have records, newest first.
  final List<DateTime> months;

  /// Who recorded, key to name.
  final Map<String, String> people;

  /// The kinds the records have (key to words), in the order given.
  final Map<String, String> kinds;

  /// The filter asked for, less what the items no longer have.
  late final HistoryFilter filter;

  /// The items that show under [filter].
  late final List<T> shown;
}
