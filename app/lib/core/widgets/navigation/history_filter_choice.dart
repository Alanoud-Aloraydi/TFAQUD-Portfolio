import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// [filter] with the menu's [chosen] line: a kind, a month or a person.
HistoryFilter chooseInHistory(HistoryFilter filter, String chosen) {
  final String value = chosen.substring(2);
  final String? key = value.isEmpty ? null : value;
  return switch (chosen[0]) {
    'k' => filter.withKind(key),
    'm' => filter.withMonth(key == null ? null : DateTime.parse(key)),
    _ => filter.withPerson(key),
  };
}

/// What the filter says when read out: «الكل», or all that is chosen,
/// «ضغط الدم، أكتوبر 2026، لينا». A kind or a person no longer among
/// [kinds] or [people] (a month read away, a member gone) is left out.
String historyFilterLabel(
  BuildContext context,
  HistoryFilter filter, {
  required Map<String, String> people,
  Map<String, String> kinds = const <String, String>{},
}) {
  final DateTime? month = filter.month;
  final List<String> parts = <String>[
    ?kinds[filter.kind],
    if (month != null) formatMonth(context, month),
    ?people[filter.person],
  ];
  return parts.isEmpty ? context.tr('history.all') : parts.join('، ');
}
