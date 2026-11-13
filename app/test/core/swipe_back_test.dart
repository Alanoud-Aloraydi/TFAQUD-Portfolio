import 'package:app/core/widgets/buttons/back_link.dart';
import 'package:app/core/widgets/navigation/swipe_back.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  /// A page with «رجوع» (or without it), counting the times it goes back.
  Future<List<int>> open(WidgetTester tester, {bool withBack = true}) async {
    final List<int> backs = <int>[];
    await pumpArabic(
      tester,
      home: SwipeBack(
        child: Scaffold(
          body: Column(
            children: <Widget>[
              if (withBack) BackLink(onPressed: () => backs.add(1)),
              const Expanded(child: Center(child: Text('page'))),
            ],
          ),
        ),
      ),
    );
    return backs;
  }

  testWidgets('a swipe to the right from the middle goes back', (tester) async {
    final List<int> backs = await open(tester);

    await tester.drag(find.text('page'), const Offset(160, 0));
    await tester.pumpAndSettle();

    expect(backs, hasLength(1));
  });

  testWidgets('a swipe to the left, or a short one, does not', (tester) async {
    final List<int> backs = await open(tester);

    await tester.drag(find.text('page'), const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.timedDrag(
      find.text('page'),
      const Offset(20, 0),
      const Duration(milliseconds: 400),
    );
    await tester.pumpAndSettle();

    expect(backs, isEmpty);
  });

  testWidgets('a page without «رجوع» stays', (tester) async {
    final List<int> backs = await open(tester, withBack: false);

    await tester.drag(find.text('page'), const Offset(160, 0));
    await tester.pumpAndSettle();

    expect(backs, isEmpty);
    expect(find.text('page'), findsOneWidget);
  });
}
