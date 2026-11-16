import 'package:equatable/equatable.dart';

/// What a history shows: one [month] or every month (null), and what one
/// [person] recorded (their account, else their name: [personKey]) or
/// what everyone did (null).
///
/// The month, not the day: a medicine taken for a year has 365 days of
/// doses, and a menu of 365 lines is no way to find one. The list already
/// carries a heading for each day, so a month narrows it enough.
class HistoryFilter extends Equatable {
  const HistoryFilter({this.month, this.person});

  static const HistoryFilter all = HistoryFilter();

  /// The first day of the month shown; null for every month.
  final DateTime? month;
  final String? person;

  HistoryFilter withMonth(DateTime? month) =>
      HistoryFilter(month: month, person: person);

  HistoryFilter withPerson(String? person) =>
      HistoryFilter(month: month, person: person);

  /// Whether a record of the day [on], by [by] (account, name), shows.
  bool shows(DateTime on, (String?, String?) by) =>
      (month == null || _sameMonth(month!, on)) &&
      (person == null || person == personKey(by.$1, by.$2));

  /// This filter less a month or a person the items no longer have, as
  /// after another month is read.
  HistoryFilter within(List<DateTime> months, Map<String, String> people) =>
      HistoryFilter(
        month:
            months.any((DateTime m) => month != null && _sameMonth(m, month!))
            ? month
            : null,
        person: people.containsKey(person) ? person : null,
      );

  /// Who recorded, as the filter knows them: their account, else their
  /// name; null for a record from before who was kept.
  static String? personKey(String? accountId, String? name) =>
      accountId ?? ((name == null || name.trim().isEmpty) ? null : name);

  /// The months of [moments], each once, newest first.
  static List<DateTime> monthsOf(Iterable<DateTime> moments) =>
      <DateTime>{for (final DateTime at in moments) DateTime(at.year, at.month)}
          .toList()
        ..sort((DateTime a, DateTime b) => b.compareTo(a));

  /// Who recorded [records] (account, name), each once: key to name.
  static Map<String, String> peopleOf(Iterable<(String?, String?)> records) =>
      <String, String>{
        for (final (String? account, String? name) in records)
          if (personKey(account, name) case final String key) key: name ?? '',
      };

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  @override
  List<Object?> get props => <Object?>[month, person];
}
