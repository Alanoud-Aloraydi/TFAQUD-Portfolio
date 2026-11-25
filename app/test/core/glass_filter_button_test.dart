import 'package:app/core/utils/history_filter.dart';
import 'package:app/core/widgets/layout/filtered_history.dart';
import 'package:app/core/widgets/navigation/glass_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Future<void> _show(WidgetTester tester, HistoryFilter filter) => pumpArabic(
  tester,
  home: Scaffold(
    body: HistoryFilters(
      months: <DateTime>[DateTime(2026, 11)],
      people: const <String, String>{'a-1': 'خالد'},
      filter: filter,
      onChanged: (_) {},
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('The filter of a history', () {
    testWidgets('chosen, it shows no words but fills, and still says what '
        'it keeps', (tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await _show(
        tester,
        HistoryFilter(month: DateTime(2026, 11), person: 'a-1'),
      );

      expect(find.textContaining('خالد'), findsNothing);
      final GlassFilterButton button = tester.widget(
        find.byType(GlassFilterButton),
      );
      expect(button.active, isTrue);
      expect(find.bySemanticsLabel(RegExp('خالد')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('on «الكل», it is the plain glass button', (tester) async {
      await _show(tester, HistoryFilter.all);

      final GlassFilterButton button = tester.widget(
        find.byType(GlassFilterButton),
      );
      expect(button.active, isFalse);
      expect(tester.getSize(find.byType(GlassFilterButton)).width, 44);
    });
  });
}
