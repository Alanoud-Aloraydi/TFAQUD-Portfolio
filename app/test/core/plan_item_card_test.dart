import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/layout/plan_facts.dart';
import 'package:app/core/widgets/layout/plan_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Widget _card({List<Widget> details = const <Widget>[Text('سارة')]}) => Scaffold(
  body: SingleChildScrollView(
    child: PlanItemCard(
      leading: const Icon(Icons.medication),
      title: const Text('ميتفورمين'),
      subtitle: const Text('أقراص'),
      status: const Text('جارية'),
      edit: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.edit),
        tooltip: 'تعديل',
      ),
      body: const <Widget>[Text('٩:٠٠ ص')],
      detailsLabel: 'تفاصيل الدواء',
      details: details,
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('PlanItemCard', () {
    testWidgets('shows the header and the body, details closed', (
      tester,
    ) async {
      await pumpArabic(tester, home: _card());

      expect(find.text('ميتفورمين'), findsOneWidget);
      expect(find.text('٩:٠٠ ص'), findsOneWidget);
      expect(find.text('سارة'), findsNothing);
    });

    testWidgets('the details line opens and closes the details', (
      tester,
    ) async {
      await pumpArabic(tester, home: _card());

      await tester.tap(find.text('تفاصيل الدواء'));
      await tester.pump();
      expect(find.text('سارة'), findsOneWidget);

      await tester.tap(find.text('تفاصيل الدواء'));
      await tester.pump();
      expect(find.text('سارة'), findsNothing);
    });

    testWidgets('has no details line when there is nothing to open', (
      tester,
    ) async {
      await pumpArabic(tester, home: _card(details: const <Widget>[]));

      expect(find.text('تفاصيل الدواء'), findsNothing);
    });

    testWidgets('keeps the pencil a 48 touch target', (tester) async {
      await pumpArabic(tester, home: _card());

      final Size size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('wraps at large text without overflow', (tester) async {
      await pumpArabic(
        tester,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: _card(),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a fact group shows its title, labels and bold values', (
    tester,
  ) async {
    await pumpArabic(
      tester,
      home: const Scaffold(
        body: PlanFactGroup(
          title: 'الأشخاص',
          children: <Widget>[
            PlanFact(icon: AppIcons.clock, label: 'الوقت', value: '9:00 ص'),
            PlanPersonFact(
              label: 'أضافه',
              name: 'سارة',
              circleId: 'circle-1',
              avatarCode: 'w1_1',
            ),
          ],
        ),
      ),
    );

    expect(find.text('الأشخاص'), findsOneWidget);
    expect(find.text('أضافه'), findsOneWidget);
    expect(find.text('سارة'), findsOneWidget);
    final Text value = tester.widget<Text>(find.text('9:00 ص'));
    expect(value.style?.fontWeight, FontWeight.w700);
    // The person's avatar beside their name.
    expect(find.byType(Image), findsOneWidget);
  });
}
