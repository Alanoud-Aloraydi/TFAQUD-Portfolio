import 'package:app/core/l10n/arabic_names.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/clock_time_slot.dart';
import 'package:app/features/home/presentation/widgets/prayer_period/prayer_period_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// Five rows whose names, times, badges and counts all differ in width.
const List<({String name, String time, bool current, int count})> _rows = [
  (name: 'الفجر', time: '04:30', current: false, count: 0),
  (name: 'الظهر', time: '12:05', current: false, count: 12),
  (name: 'العصر', time: '15:20', current: true, count: 3),
  (name: 'المغرب', time: '18:11', current: false, count: 1),
  (name: 'العشاء', time: '19:41', current: false, count: 0),
];

Future<void> _pumpRows(WidgetTester tester, double textScale) => pumpArabic(
  tester,
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            for (final row in _rows)
              PrayerPeriodTitle(
                name: row.name,
                time: clockText(row.time),
                current: row.current,
                taskCount: row.count,
              ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  for (final double scale in <double>[1, 2]) {
    testWidgets('all prayer times share one column at text scale $scale', (
      tester,
    ) async {
      await _pumpRows(tester, scale);

      final Iterable<Rect> slots = tester
          .widgetList(find.byType(ClockTimeSlot))
          .map((slot) => tester.getRect(find.byWidget(slot)));
      expect(slots, hasLength(_rows.length));
      expect(slots.map((rect) => rect.left).toSet(), hasLength(1));
      expect(slots.map((rect) => rect.width).toSet(), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('the time text ends at the end side of its slot', (tester) async {
    await _pumpRows(tester, 2);

    for (final row in _rows) {
      final Finder text = find.text(clockText(row.time));
      final Rect slot = tester.getRect(
        find.ancestor(of: text, matching: find.byType(ClockTimeSlot)),
      );
      // Arabic is right to left, so the end of a line is its left edge.
      expect(tester.getRect(text).left, slot.left);
    }
  });
}
