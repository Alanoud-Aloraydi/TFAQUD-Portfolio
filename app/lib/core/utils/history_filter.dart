import 'package:equatable/equatable.dart';

/// What a history shows: one [month] or every month (null), what one
/// [person] recorded (their account, else their name: [personKey]) or
/// what everyone did (null), and one [kind] of record or every kind.
///
/// The month, not the day: a medicine taken for a year has 365 days of
/// doses, and a menu of 365 lines is no way to find one. The list already
/// carries a heading for each day, so a month narrows it enough.
class HistoryFilter extends Equatable {
  const HistoryFilter({this.month, this.person, this.kind});

  static const HistoryFilter all = HistoryFilter();

  /// The first day of the month shown; null for every month.
  final DateTime? month;
  final String? person;

  /// A kind of record («glucose», «bp» of the readings); null for all.
  final String? kind;

  HistoryFilter withMonth(DateTime? month) =>
      HistoryFilter(month: month, person: person, kind: kind);

  HistoryFilter withPerson(String? person) =>
      HistoryFilter(month: month, person: person, kind: kind);

  HistoryFilter withKind(String? kind) =>
      HistoryFilter(month: month, person: person, kind: kind);

  /// Whether a record of the day [on], by [by] (account, name), of the
  /// kind [of], shows.
  bool shows(DateTime on, (String?, String?) by, [String? of]) =>
      (month == null || _sameMonth(month!, on)) &&
      (person == null || person == personKey(by.$1, by.$2)) &&
      (kind == null || kind == of);

  /// This filter less a month, a person or a kind the items no longer
  /// have, as after another month is read.
  HistoryFilter within(
    List<DateTime> months,
    Map<String, String> people, [
    Map<String, String> kinds = const <String, String>{},
  ]) => HistoryFilter(
    month: months.any((DateTime m) => month != null && _sameMonth(m, month!))
        ? month
        : null,
    person: people.containsKey(person) ? person : null,
    kind: kinds.containsKey(kind) ? kind : null,
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
  List<Object?> get props => <Object?>[month, person, kind];
}
