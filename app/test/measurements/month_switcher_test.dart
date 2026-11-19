import 'package:app/core/l10n/app_calendar.dart';
import 'package:app/core/utils/calendar_month.dart';
import 'package:app/features/measurements/presentation/widgets/month_switcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Future<List<int>> _pump(
  WidgetTester tester, {
  required bool canGoBack,
  required bool canGoForward,
}) async {
  final List<int> moves = <int>[];
  await pumpArabic(
    tester,
    home: Scaffold(
      body: MonthSwitcher(
        month: CalendarMonth.of(DateTime(2026, 11), DateCalendar.gregorian),
        canGoForward: canGoForward,
        canGoBack: canGoBack,
        onChange: moves.add,
      ),
    ),
  );
  return moves;
}

void main() {
  setUpAll(initTestLocalization);

  testWidgets('the first month with a reading goes back no further', (
    WidgetTester tester,
  ) async {
    final List<int> moves = await _pump(
      tester,
      canGoBack: false,
      canGoForward: true,
    );

    await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
    await tester.tap(find.byIcon(CupertinoIcons.chevron_left));

    expect(moves, <int>[1]);
  });

  testWidgets('a month between moves both ways', (WidgetTester tester) async {
    final List<int> moves = await _pump(
      tester,
      canGoBack: true,
      canGoForward: true,
    );

    await tester.tap(find.byIcon(CupertinoIcons.chevron_right));
    await tester.tap(find.byIcon(CupertinoIcons.chevron_left));

    expect(moves, <int>[-1, 1]);
  });
}
