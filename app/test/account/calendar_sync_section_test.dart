import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/phone_fakes.dart';
import '../support/widget_harness.dart';

void main() {
  group('CalendarSyncSection', () {
    late FakeCalendarSync calendar;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() {
      calendar = FakeCalendarSync(<String>{'c-1:doses'});
      GetIt.I.registerSingleton<CalendarSync>(calendar);
    });

    tearDown(() => GetIt.I.reset());

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('ar')],
          startLocale: const Locale('ar'),
          path: 'assets/translations',
          assetLoader: const TestTranslations(),
          child: Builder(
            builder: (context) => MaterialApp(
              theme: AppTheme.lightTheme,
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: const Scaffold(
                body: CalendarSyncCircleList(
                  circles: <CalendarSyncCircle>[
                    (id: 'c-1', name: 'دائرة حامد', leading: null),
                    (id: 'c-2', name: 'دائرة محمد', leading: null),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('each circle is closed, and says how many switches are on', (
      tester,
    ) async {
      await open(tester);

      final String doses = 'circle_overview.calendar_sync_doses'.tr();
      expect(find.text(doses), findsNothing);
      expect(find.text('1 من 3'), findsOneWidget);
      expect(
        find.text('circle_overview.calendar_sync_off'.tr()),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('دائرة حامد، 1 من 3')),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a circle opens to its switches, and the count follows', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.text('دائرة حامد'));
      await tester.pumpAndSettle();
      expect(
        find.text('circle_overview.calendar_sync_doses'.tr()),
        findsOneWidget,
      );
      // Only the open circle's three switches.
      expect(find.byType(CupertinoSwitch), findsNWidgets(3));

      // Turn on the measurements, the second switch.
      await tester.tap(find.byType(CupertinoSwitch).at(1));
      await tester.pumpAndSettle();

      expect(calendar.on, contains('c-1:measurements'));
      expect(find.text('2 من 3'), findsOneWidget);

      // Closed again: the switches go, the count stays.
      await tester.tap(find.text('دائرة حامد'));
      await tester.pumpAndSettle();
      expect(
        find.text('circle_overview.calendar_sync_doses'.tr()),
        findsNothing,
      );
      expect(find.text('2 من 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
