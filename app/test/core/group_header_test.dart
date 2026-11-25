import 'package:app/core/widgets/layout/group_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  testWidgets('«إخفاء» sits at the far edge of the group, over the edge of '
      'the cards under it, not halfway', (tester) async {
    await pumpArabic(
      tester,
      home: Scaffold(
        body: GroupHeader(
          title: 'سجل الجرعات',
          count: 1,
          expanded: true,
          onToggle: () {},
        ),
      ),
    );

    // Right to left: the far edge is the left one, at 0.
    expect(tester.getTopLeft(find.byType(FoldAffordance)).dx, 0);
  });
}
