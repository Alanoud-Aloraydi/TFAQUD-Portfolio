import 'package:equatable/equatable.dart';

/// What a history shows: one [day] or every day (null), and what one
/// [person] recorded (their account, else their name: [personKey]) or
/// what everyone did (null).
class HistoryFilter extends Equatable {
  const HistoryFilter({this.day, this.person});

  static const HistoryFilter all = HistoryFilter();

  final DateTime? day;
  final String? person;

  HistoryFilter withDay(DateTime? day) =>
      HistoryFilter(day: day, person: person);

  HistoryFilter withPerson(String? person) =>
      HistoryFilter(day: day, person: person);

  /// Whether a record of the day [on], by [by] (account, name), shows.
  bool shows(DateTime on, (String?, String?) by) =>
      (day == null || _sameDay(day!, on)) &&
      (person == null || person == personKey(by.$1, by.$2));

  /// This filter less a day or a person not in [days] or [people], as
  /// after another month is read.
  HistoryFilter within(List<DateTime> days, Map<String, String> people) =>
      HistoryFilter(
        day: days.any((DateTime d) => day != null && _sameDay(d, day!))
            ? day
            : null,
        person: people.containsKey(person) ? person : null,
      );

  /// Who recorded, as the filter knows them: their account, else their
  /// name; null for a record from before who was kept.
  static String? personKey(String? accountId, String? name) =>
      accountId ?? ((name == null || name.trim().isEmpty) ? null : name);

  /// The days of [moments], each once, newest first.
  static List<DateTime> daysOf(Iterable<DateTime> moments) => <DateTime>{
    for (final DateTime at in moments) DateTime(at.year, at.month, at.day),
  }.toList()..sort((DateTime a, DateTime b) => b.compareTo(a));

  /// Who recorded [records] (account, name), each once: key to name.
  static Map<String, String> peopleOf(Iterable<(String?, String?)> records) =>
      <String, String>{
        for (final (String? account, String? name) in records)
          if (personKey(account, name) case final String key) key: name ?? '',
      };

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  List<Object?> get props => <Object?>[day, person];
}
