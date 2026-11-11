import 'package:app/core/feedback/app_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

Widget _button(ToastKind kind) => Scaffold(
  body: Builder(
    builder: (BuildContext context) => TextButton(
      onPressed: () =>
          AppToast.show(context, 'toast.medication_saved', kind: kind),
      child: const Text('go'),
    ),
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('AppToast', () {
    testWidgets('shows the translated message with a success icon', (
      tester,
    ) async {
      await pumpArabic(tester, home: _button(ToastKind.success));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('toast.medication_saved'.tr()), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('an error has another icon, so colour is not the only cue', (
      tester,
    ) async {
      await pumpArabic(tester, home: _button(ToastKind.error));
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('is a live region, so VoiceOver reads it out', (tester) async {
      await pumpArabic(tester, home: _button(ToastKind.success));
      await tester.tap(find.text('go'));
      await tester.pump();
      final Finder live = find.ancestor(
        of: find.text('toast.medication_saved'.tr()),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && widget.properties.liveRegion == true,
        ),
      );
      expect(live, findsOneWidget);
    });

    testWidgets('a new toast replaces the one on screen', (tester) async {
      await pumpArabic(tester, home: _button(ToastKind.success));
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('toast.medication_saved'.tr()), findsOneWidget);
    });

    testWidgets('showText takes a messenger kept before a navigation', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () =>
                  AppToast.showText(ScaffoldMessenger.of(context), 'جاهز'),
              child: const Text('go'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pump();
      expect(find.text('جاهز'), findsOneWidget);
    });
  });
}
