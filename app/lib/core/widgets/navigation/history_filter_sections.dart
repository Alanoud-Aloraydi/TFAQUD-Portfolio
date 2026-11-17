import 'package:app/core/l10n/medication_format.dart';
import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// The key a month is chosen by; empty means «كل الشهور».
String historyMonthKey(DateTime? month) =>
    month == null ? '' : month.toIso8601String();

/// The groups of the history menu: the [kinds] of record when there are
/// two or more («الكل»، «سكر الدم»، «ضغط الدم»), the months that have
/// records, then who recorded. A value is its group's letter and its key,
/// so one menu can answer three questions («k:bp», «m:2026-10-01…»,
/// «p:lina»).
List<List<GlassMenuItem<String>>> historyFilterSections(
  BuildContext context, {
  required List<DateTime> months,
  required Map<String, String> people,
  required HistoryFilter filter,
  Map<String, String> kinds = const <String, String>{},
}) {
  final String month = historyMonthKey(filter.month);
  final String person = filter.person ?? '';
  final String kind = filter.kind ?? '';
  return <List<GlassMenuItem<String>>>[
    if (kinds.length > 1)
      <GlassMenuItem<String>>[
        GlassMenuItem<String>(
          value: 'k:',
          label: context.tr('history.all'),
          selected: kind.isEmpty,
        ),
        for (final MapEntry<String, String> entry in kinds.entries)
          GlassMenuItem<String>(
            value: 'k:${entry.key}',
            label: entry.value,
            selected: entry.key == kind,
          ),
      ],
    <GlassMenuItem<String>>[
      GlassMenuItem<String>(
        value: 'm:',
        label: context.tr('history.all_months'),
        selected: month.isEmpty,
      ),
      for (final DateTime value in months)
        GlassMenuItem<String>(
          value: 'm:${historyMonthKey(value)}',
          label: formatMonth(context, value),
          selected: historyMonthKey(value) == month,
        ),
    ],
    <GlassMenuItem<String>>[
      GlassMenuItem<String>(
        value: 'p:',
        label: context.tr('history.all_people'),
        selected: person.isEmpty,
      ),
      for (final MapEntry<String, String> entry in people.entries)
        GlassMenuItem<String>(
          value: 'p:${entry.key}',
          label: entry.value,
          selected: entry.key == person,
        ),
    ],
  ];
}
