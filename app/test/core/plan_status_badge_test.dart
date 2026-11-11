import 'package:app/core/widgets/status/plan_status.dart';
import 'package:app/core/widgets/status/plan_status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

void main() {
  setUpAll(initTestLocalization);

  group('PlanStatusBadge', () {
    test('each status has its own colour', () {
      final Set<Color> fills = <Color>{
        for (final PlanStatus status in PlanStatus.values)
          PlanStatusBadge.background(status),
      };
      expect(fills.length, PlanStatus.values.length);
    });

    test('completed text stays readable on its fill', () {
      final double fill = PlanStatusBadge.background(PlanStatus.completed)
          .computeLuminance();
      final double text = PlanStatusBadge.foreground(PlanStatus.completed)
          .computeLuminance();
      expect((text + 0.05) / (fill + 0.05), greaterThan(4.5));
    });

    testWidgets('shows the translated label of every status', (tester) async {
      for (final PlanStatus status in PlanStatus.values) {
        await pumpArabic(tester, home: Scaffold(body: PlanStatusBadge(status)));
        expect(find.text('plan_status.${status.name}'.tr()), findsOneWidget);
      }
    });

    testWidgets('completed uses its own fill', (tester) async {
      await pumpArabic(
        tester,
        home: const Scaffold(body: PlanStatusBadge(PlanStatus.completed)),
      );
      final Container box = tester.widget(
        find.ancestor(
          of: find.text('plan_status.completed'.tr()),
          matching: find.byType(Container),
        ),
      );
      expect(
        (box.decoration! as BoxDecoration).color,
        PlanStatusBadge.background(PlanStatus.completed),
      );
    });
  });
}
