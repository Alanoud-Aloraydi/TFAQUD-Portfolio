import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/materials/tab_bar_style.dart';
import 'package:app/features/shell/widgets/frosted_tab_bar.dart';
import 'package:crystal_navigation_bar/crystal_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

CrystalNavigationBar _bar(WidgetTester tester) =>
    tester.widget<CrystalNavigationBar>(find.byType(CrystalNavigationBar));

Future<void> _pumpBar(WidgetTester tester) => pumpArabic(
  tester,
  home: Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: FrostedTabBar(currentIndex: 0, onTab: (_) {}),
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('FrostedTabBar press state', () {
    testWidgets('is transparent at rest', (WidgetTester tester) async {
      await _pumpBar(tester);

      expect(_bar(tester).backgroundColor, AppTabBarStyle.restFill);
      expect(_bar(tester).backgroundColor.a, 0);
    });

    testWidgets('turns dark while pressed and transparent after', (
      WidgetTester tester,
    ) async {
      await _pumpBar(tester);

      final TestGesture finger = await tester.startGesture(
        tester.getCenter(find.byType(CrystalNavigationBar)),
      );
      await tester.pumpAndSettle();
      expect(_bar(tester).backgroundColor, AppTabBarStyle.pressedFill);
      expect(_bar(tester).selectedItemColor, AppTabBarStyle.pressedForeground);

      await finger.up();
      await tester.pumpAndSettle();
      expect(_bar(tester).backgroundColor, AppTabBarStyle.restFill);
    });

    testWidgets('keeps a 48 touch target and labels at large text', (
      WidgetTester tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pumpBar(tester);

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(CrystalNavigationBar)).height,
        greaterThanOrEqualTo(AppSizes.button),
      );
      expect(find.text('اليوم'), findsWidgets);
    });
  });
}
