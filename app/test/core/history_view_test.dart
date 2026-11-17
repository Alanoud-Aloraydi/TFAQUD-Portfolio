import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/utils/history_view.dart';
import 'package:app/core/widgets/navigation/history_filter_choice.dart';
import 'package:app/core/widgets/navigation/history_filter_sections.dart';
import 'package:app/core/widgets/overlays/glass_menu_item.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// A reading: its kind and its day of November 2026, by لينا.
typedef _Reading = ({String kind, int day});

const Map<String, String> _kinds = <String, String>{
  'glucose': 'سكر الدم',
  'bp': 'ضغط الدم',
};

HistoryView<_Reading> _view(List<_Reading> items, HistoryFilter filter) =>
    HistoryView<_Reading>(
      items,
      filter,
      dayOf: (r) => DateTime(2026, 11, r.day),
      byOf: (_) => ('a-1', 'لينا'),
      kinds: _kinds,
      kindOf: (r) => r.kind,
    );

void main() {
  setUpAll(initTestLocalization);

  const List<_Reading> both = <_Reading>[
    (kind: 'bp', day: 17),
    (kind: 'glucose', day: 16),
    (kind: 'bp', day: 15),
  ];

  group('A history filtered by kind', () {
    test('keeps one kind, and offers only the kinds it has', () {
      final HistoryView<_Reading> view = _view(
        both,
        HistoryFilter.all.withKind('bp'),
      );

      expect(view.kinds, _kinds);
      expect(view.shown.map((r) => r.day).toList(), <int>[17, 15]);
    });

    test('a kind the readings no longer have is off', () {
      final HistoryView<_Reading> view = _view(<_Reading>[
        (kind: 'glucose', day: 16),
      ], HistoryFilter.all.withKind('bp'));

      expect(view.kinds, <String, String>{'glucose': 'سكر الدم'});
      expect(view.filter.kind, isNull);
      expect(view.shown, hasLength(1));
    });

    test('a kind keeps the month and the person chosen with it', () {
      final HistoryFilter filter = HistoryFilter.all
          .withPerson('a-1')
          .withMonth(DateTime(2026, 11));

      expect(chooseInHistory(filter, 'k:bp').kind, 'bp');
      expect(chooseInHistory(filter, 'k:bp').person, 'a-1');
      expect(chooseInHistory(filter, 'k:bp').month, DateTime(2026, 11));
      expect(chooseInHistory(filter.withKind('bp'), 'k:').kind, isNull);
    });

    testWidgets('its menu starts with «الكل»، «سكر الدم»، «ضغط الدم», and '
        'leaves the group out with one kind only', (tester) async {
      late List<List<GlassMenuItem<String>>> two;
      late List<List<GlassMenuItem<String>>> one;
      late String label;
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext context) {
            List<List<GlassMenuItem<String>>> sections(
              Map<String, String> kinds,
            ) => historyFilterSections(
              context,
              months: <DateTime>[DateTime(2026, 11)],
              people: const <String, String>{'a-1': 'لينا'},
              filter: HistoryFilter.all,
              kinds: kinds,
            );
            two = sections(_kinds);
            one = sections(const <String, String>{'bp': 'ضغط الدم'});
            label = historyFilterLabel(
              context,
              HistoryFilter.all.withKind('bp'),
              people: const <String, String>{},
              kinds: _kinds,
            );
            return const SizedBox();
          },
        ),
      );

      expect(two, hasLength(3));
      expect(two.first.map((item) => item.label).toList(), <String>[
        'history.all'.tr(),
        'سكر الدم',
        'ضغط الدم',
      ]);
      expect(one, hasLength(2));
      expect(label, 'ضغط الدم');
    });
  });
}
