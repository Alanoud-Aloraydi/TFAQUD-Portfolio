import 'package:app/core/widgets/loading/loading_note.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/widget_harness.dart';

double _turns(WidgetTester tester) => tester
    .widget<RotationTransition>(find.byType(RotationTransition))
    .turns
    .value;

void main() {
  setUpAll(initTestLocalization);

  group('The loader', () {
    testWidgets('turns the logo a round every 1.6 seconds, as the design', (
      tester,
    ) async {
      await pumpArabic(
        tester,
        home: const Scaffold(body: Center(child: TfaqudLoader(size: 44))),
      );

      final Image logo = tester.widget(find.byType(Image));
      expect((logo.image as AssetImage).assetName, TfaqudLoader.logo);
      await tester.pump(const Duration(milliseconds: 400));
      expect(_turns(tester), closeTo(0.25, 0.01));
    });

    testWidgets('stays still when motion is reduced', (tester) async {
      await pumpArabic(
        tester,
        home: Builder(
          builder: (BuildContext context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Scaffold(body: Center(child: TfaqudLoader(size: 44))),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(_turns(tester), 0);
    });

    testWidgets('a loading page says «جارٍ التحميل» under it', (tester) async {
      await pumpArabic(tester, home: const Scaffold(body: LoadingNote()));

      expect(find.byType(TfaqudLoader), findsOneWidget);
      expect(find.text('common.loading'.tr()), findsOneWidget);
    });
  });
}
