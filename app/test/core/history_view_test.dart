import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/utils/history_view.dart';
import 'package:app/core/widgets/navigation/history_filter_choice.dart';
import 'package:app/core/widgets/navigation/history_filter_sections.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// A record: its day and who made it (account, name).
typedef _Record = ({DateTime day, String account, String name});

HistoryView<_Record> _view(List<_Record> items, HistoryFilter filter) =>
    HistoryView<_Record>(
      items,
      filter,
      dayOf: (r) => r.day,
      byOf: (r) => (r.account, r.name),
    );

void main() {
  setUpAll(initTestLocalization);

  final List<_Record> records = <_Record>[
    (day: DateTime(2026, 11, 17), account: 'a-1', name: 'لينا'),
    (day: DateTime(2026, 11, 16), account: 'a-2', name: 'خالد'),
    (day: DateTime(2026, 10, 30), account: 'a-1', name: 'لينا'),
  ];

  group('A history filter', () {
    test('offers the months and the people the records have', () {
      final HistoryView<_Record> view = _view(records, HistoryFilter.all);

      expect(view.months, <DateTime>[DateTime(2026, 11), DateTime(2026, 10)]);
      expect(view.people, <String, String>{'a-1': 'لينا', 'a-2': 'خالد'});
      expect(view.shown, hasLength(3));
    });

    test('keeps one month and one person together', () {
      final HistoryView<_Record> view = _view(
        records,
        HistoryFilter(month: DateTime(2026, 11), person: 'a-1'),
      );

      expect(view.shown.single.day, DateTime(2026, 11, 17));
    });

    test('a person the records no longer have is off', () {
      final HistoryView<_Record> view = _view(
        records.take(1).toList(),
        HistoryFilter.all.withPerson('a-2'),
      );

      expect(view.filter.person, isNull);
      expect(view.shown, hasLength(1));
    });

    test('a menu line changes only its own group', () {
      final HistoryFilter filter = HistoryFilter.all.withPerson('a-1');

      final HistoryFilter chosen = chooseInHistory(
        filter,
        'm:${historyMonthKey(DateTime(2026, 10))}',
      );
      expect(chosen.month, DateTime(2026, 10));
      expect(chosen.person, 'a-1');
      expect(chooseInHistory(chosen, 'p:').person, isNull);
    });

    testWidgets('its menu has the months, then the people, and no kinds: '
        'the kind is chosen at the top of the page', (tester) async {
      late List<List<GlassMenuItem<String>>> sections;
      late String label;
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext context) {
            sections = historyFilterSections(
              context,
              months: <DateTime>[DateTime(2026, 11)],
              people: const <String, String>{'a-1': 'لينا'},
              filter: HistoryFilter.all,
            );
            label = historyFilterLabel(
              context,
              HistoryFilter.all.withPerson('a-1'),
              people: const <String, String>{'a-1': 'لينا'},
            );
            return const SizedBox();
          },
        ),
      );

      expect(sections, hasLength(2));
      expect(sections.first.first.label, 'history.all_months'.tr());
      expect(sections.last.first.label, 'history.all_people'.tr());
      expect(label, 'لينا');
    });
  });
}
