import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/account/presentation/widgets/calendar_sync_circle_list.dart';
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
  group('CalendarSyncCircleList', () {
    late FakeCalendarSync calendar;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(() {
      calendar = FakeCalendarSync(<String>{
        'c-1:doses',
        'c-1:measurements',
        'c-1:appointments',
      });
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

    testWidgets('one switch a circle, showing the saved choice', (
      tester,
    ) async {
      await open(tester);

      expect(find.byType(CupertinoSwitch), findsNWidgets(2));
      expect(find.text('دائرة حامد'), findsOneWidget);
      expect(find.text('دائرة محمد'), findsOneWidget);
      final List<CupertinoSwitch> switches = tester
          .widgetList<CupertinoSwitch>(find.byType(CupertinoSwitch))
          .toList();
      expect(switches.first.value, isTrue);
      expect(switches.last.value, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('off takes every kind off that circle at once', (tester) async {
      await open(tester);

      await tester.tap(find.byType(CupertinoSwitch).first);
      await tester.pumpAndSettle();

      expect(calendar.on, isEmpty);
      expect(
        tester
            .widgetList<CupertinoSwitch>(find.byType(CupertinoSwitch))
            .first
            .value,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('turning a circle on asks first, then takes every kind', (
      tester,
    ) async {
      await open(tester);

      await tester.tap(find.byType(CupertinoSwitch).last);
      await tester.pumpAndSettle();

      expect(
        find.text('circle_overview.calendar_sync_confirm_title'.tr()),
        findsOneWidget,
      );
      expect(calendar.on, isNot(contains('c-2:doses')));

      await tester.tap(
        find.text('circle_overview.calendar_sync_confirm_cancel'.tr()),
      );
      await tester.pumpAndSettle();
      expect(calendar.on, isNot(contains('c-2:doses')));

      await tester.tap(find.byType(CupertinoSwitch).last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('circle_overview.calendar_sync_confirm_accept'.tr()),
      );
      await tester.pumpAndSettle();

      expect(
        calendar.on,
        containsAll(<String>[
          'c-2:doses',
          'c-2:measurements',
          'c-2:appointments',
        ]),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
