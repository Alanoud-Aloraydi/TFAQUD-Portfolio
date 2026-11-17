import 'dart:async';

import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/app_settings_page.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/services/reminders/reminders_enabled.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/forms/notifications_tap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/widget_harness.dart';

/// The reminders, counting the phone's questions.
class _Reminders extends Fake implements DoseReminders {
  int asks = 0;

  @override
  final RemindersEnabled enabled = RemindersEnabled();

  @override
  Future<AppPermission> requestPermission() async {
    asks++;
    return AppPermission.granted;
  }
}

void main() {
  late _Reminders reminders;
  int settingsOpened = 0;

  setUpAll(initTestLocalization);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    reminders = _Reminders();
    GetIt.I.registerSingleton<DoseReminders>(reminders);
    // No Settings page in a test: count the leaving, and say it failed.
    settingsOpened = 0;
    final Future<bool> Function() opener = appSettingsOpener;
    appSettingsOpener = () async {
      settingsOpened++;
      return false;
    };
    addTearDown(() => appSettingsOpener = opener);
  });

  tearDown(GetIt.I.reset);

  /// Turns the notifications switch on while the phone answers [allowed].
  Future<void> switchOn(WidgetTester tester, AppPermission allowed) async {
    await pumpArabic(
      tester,
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () =>
                unawaited(tapNotifications(context, allowed, wanted: true)),
            child: const Text('on'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('on'));
    await tester.pump();
  }

  Finder title() => find.text('account.notifications_confirm_title'.tr());

  group('The notifications switch', () {
    testWidgets('never asked: what they are for, then the phone asks', (
      tester,
    ) async {
      await switchOn(tester, AppPermission.notAsked);

      expect(title(), findsOneWidget);
      expect(reminders.asks, 0);
      await tester.tap(find.text('account.notifications_confirm_accept'.tr()));
      await tester.pumpAndSettle();
      expect(reminders.asks, 1);
    });

    testWidgets('never asked and «ليس الآن»: the phone is not asked', (
      tester,
    ) async {
      await switchOn(tester, AppPermission.notAsked);

      await tester.tap(find.text('account.notifications_confirm_cancel'.tr()));
      await tester.pumpAndSettle();
      expect(reminders.asks, 0);
    });

    testWidgets('refused before: a word first, then the phone Settings', (
      tester,
    ) async {
      await switchOn(tester, AppPermission.denied);

      expect(title(), findsNothing);
      expect(find.text('account.notifications_opening'.tr()), findsOneWidget);
      // The word comes in; the wait starts once it is fully on screen, so
      // it is read before Settings opens.
      await tester.pumpAndSettle();
      await tester.pump(AppMotion.settingsLead - const Duration(seconds: 1));
      expect(settingsOpened, 0);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(settingsOpened, 1);
      // Settings did not open, so it says so.
      expect(
        find.text('account.notifications_settings_failed'.tr()),
        findsOneWidget,
      );
      expect(reminders.asks, 0);
    });

    testWidgets('allowed: the person turns them on and off here', (
      tester,
    ) async {
      await reminders.enabled.set(false);
      await switchOn(tester, AppPermission.granted);
      await tester.pumpAndSettle();

      expect(title(), findsNothing);
      expect(reminders.enabled.on.value, isTrue);
      expect(reminders.asks, 0);
    });
  });
}
