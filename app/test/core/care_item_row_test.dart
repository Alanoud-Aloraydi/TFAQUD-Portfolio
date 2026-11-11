import 'package:app/core/theme/foundations/app_item_card.dart';
import 'package:app/core/widgets/layout/care_item_row.dart';
import 'package:app/core/widgets/layout/today_row_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Widget _row({VoidCallback? onTap, Widget? actions}) => Scaffold(
  body: CareItemRow(
    time: '٩:٠٠ ص',
    leading: const TodayTaskKindIcon(
      icon: Icons.medication,
      background: Colors.green,
    ),
    title: 'ميتفورمين 500 ملغ',
    subtitle: 'حبة واحدة',
    status: const TodayTaskStatusBadge(
      text: 'ينتظر',
      tone: TodayStatusTone.attention,
    ),
    onTap: onTap,
    actions: actions,
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('CareItemRow', () {
    testWidgets('puts the time first (on the right) and the status last', (
      tester,
    ) async {
      await pumpArabic(tester, home: _row());

      final double time = tester.getCenter(find.text('٩:٠٠ ص')).dx;
      final double title = tester.getCenter(find.text('ميتفورمين 500 ملغ')).dx;
      final double status = tester.getCenter(find.text('ينتظر')).dx;
      expect(time, greaterThan(title));
      expect(title, greaterThan(status));
    });

    testWidgets('the tap area is at least 48 tall and reports taps', (
      tester,
    ) async {
      int taps = 0;
      await pumpArabic(tester, home: _row(onTap: () => taps++));

      final Size area = tester.getSize(find.byType(InkWell));
      expect(area.height, greaterThanOrEqualTo(AppItemCard.touch));
      await tester.tap(find.text('ميتفورمين 500 ملغ'));
      expect(taps, 1);
    });

    testWidgets('reads as one item to the screen reader', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpArabic(tester, home: _row(onTap: () {}));

      final node = tester.getSemantics(find.text('ميتفورمين 500 ملغ'));
      expect(node.label, contains('ميتفورمين'));
      expect(node.label, contains('ينتظر'));
      handle.dispose();
    });

    testWidgets('at large text the status drops under the title', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _row(),
        ),
      );

      final double title = tester.getTopLeft(find.text('ميتفورمين 500 ملغ')).dy;
      final double status = tester.getTopLeft(find.text('ينتظر')).dy;
      expect(status, greaterThan(title));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows the actions under the header', (tester) async {
      await pumpArabic(tester, home: _row(actions: const Text('تسجيل')));

      final double actions = tester.getCenter(find.text('تسجيل')).dy;
      final double title = tester.getCenter(find.text('حبة واحدة')).dy;
      expect(actions, greaterThan(title));
    });
  });
}
