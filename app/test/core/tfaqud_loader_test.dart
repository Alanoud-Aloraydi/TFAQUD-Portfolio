import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

/// How far the loader's logo has turned, in rounds.
double _turns(WidgetTester tester) => tester
    .widget<RotationTransition>(
      find.descendant(
        of: find.byType(TfaqudLoader),
        matching: find.byType(RotationTransition),
      ),
    )
    .turns
    .value;

/// [child] with motion reduced, as the phone's setting does.
Widget _calm(Widget child) => Builder(
  builder: (BuildContext context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  setUpAll(initTestLocalization);

  group('The loader', () {
    testWidgets('turns the logo a round every 1.6 seconds, as the design', (
      tester,
    ) async {
      // Still at first: the page settles (as a pulled page's loader rests
      // before it is let go), then it turns.
      final ValueNotifier<bool> turning = ValueNotifier<bool>(false);
      addTearDown(turning.dispose);
      await pumpArabic(
        tester,
        home: Scaffold(
          body: Center(
            child: ValueListenableBuilder<bool>(
              valueListenable: turning,
              builder: (_, bool on, _) => TfaqudLoader(size: 44, animating: on),
            ),
          ),
        ),
      );
      final Image logo = tester.widget(find.byType(Image));
      expect((logo.image as AssetImage).assetName, TfaqudLoader.logo);

      turning.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_turns(tester), closeTo(0.25, 0.01));

      // Stopped again before the test ends, so nothing is left turning.
      turning.value = false;
      await tester.pump();
    });

    testWidgets('stays still when motion is reduced', (tester) async {
      await pumpArabic(
        tester,
        home: _calm(
          const Scaffold(body: Center(child: TfaqudLoader(size: 44))),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(_turns(tester), 0);
    });

    testWidgets('a loading page says «جارٍ التحميل» under it', (tester) async {
      await pumpArabic(
        tester,
        home: _calm(const Scaffold(body: LoadingNote())),
      );

      expect(find.byType(TfaqudLoader), findsOneWidget);
      expect(find.text('common.loading'.tr()), findsOneWidget);
    });
  });
}
