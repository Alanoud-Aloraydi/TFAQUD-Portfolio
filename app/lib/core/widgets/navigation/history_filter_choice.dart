import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// [filter] with the menu's [chosen] line: a month or a person.
HistoryFilter chooseInHistory(HistoryFilter filter, String chosen) {
  final String value = chosen.substring(2);
  final String? key = value.isEmpty ? null : value;
  return switch (chosen[0]) {
    'm' => filter.withMonth(key == null ? null : DateTime.parse(key)),
    _ => filter.withPerson(key),
  };
}

/// What the filter says when read out: «الكل», or all that is chosen,
/// «أكتوبر 2026، لينا». A person no longer among [people] (a month read
/// away, a member gone) is left out.
String historyFilterLabel(
  BuildContext context,
  HistoryFilter filter, {
  required Map<String, String> people,
}) {
  final DateTime? month = filter.month;
  final List<String> parts = <String>[
    if (month != null) formatMonth(context, month),
    ?people[filter.person],
  ];
  return parts.isEmpty ? context.tr('history.all') : parts.join('، ');
}
