import 'package:app/core/widgets/feedback/retry_view.dart';
import 'package:app/core/widgets/layout/record_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Widget _card({VoidCallback? onTap}) => Scaffold(
  body: RecordItemCard(
    leading: const Icon(Icons.medication),
    title: const Text('ميتفورمين'),
    subtitle: const Text('بدأ في 7 نوفمبر'),
    status: const Text('جارية'),
    body: const <Widget>[Text('آخر جرعة')],
    onTap: onTap,
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('RecordItemCard', () {
    testWidgets('the whole card opens on tap', (tester) async {
      int taps = 0;
      await pumpArabic(tester, home: _card(onTap: () => taps++));

      await tester.tap(find.text('آخر جرعة'));
      expect(taps, 1);
    });

    testWidgets('shows header and body parts', (tester) async {
      await pumpArabic(tester, home: _card());

      expect(find.text('ميتفورمين'), findsOneWidget);
      expect(find.text('جارية'), findsOneWidget);
      expect(find.text('آخر جرعة'), findsOneWidget);
    });
  });

  testWidgets('RetryView asks again on tap', (tester) async {
    int retries = 0;
    await pumpArabic(
      tester,
      home: Scaffold(
        body: RetryView(messageKey: 'error.unknown', onRetry: () => retries++),
      ),
    );

    await tester.tap(find.byType(FilledButton));
    expect(retries, 1);
  });
}
