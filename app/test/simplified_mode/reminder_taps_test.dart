import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/features/simplified_mode/domain/entities/reminder_payload.dart';
import 'package:app/features/simplified_mode/domain/entities/today_task.dart';
import 'package:app/features/simplified_mode/presentation/cubit/reminder_taps.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/phone_fakes.dart';

/// A dose reminder of one circle, as [DoseReminders] sets it.
const String _dose = '${doseReminderPayload}c-1';

void main() {
  group('ReminderTaps', () {
    late FakePhoneNotifications phone;
    late List<ReminderRequest> opened;
    late List<String> snoozed;
    bool dayRead = false;

    ReminderTaps build() => ReminderTaps(
      phone: phone,
      hasDay: () => dayRead,
      snooze: (String tap) async => snoozed.add(tap),
      open: opened.add,
    );

    setUp(() {
      phone = FakePhoneNotifications();
      opened = <ReminderRequest>[];
      snoozed = <String>[];
      dayRead = false;
    });

    test('a launch tap opens nothing until the day is read, then opens it', () {
      phone.launchTap = _dose;
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      // The screen is built and asks at once: the day is not read yet.
      taps.openPending();
      expect(opened, isEmpty);

      dayRead = true;
      taps.openPending();

      expect(opened.single.kind, TodayTaskKind.medication);
    });

    test('a launch tap is not lost when the day was read before the '
        'screen', () {
      phone.launchTap = _dose;
      dayRead = true;
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      // No change of day follows, so this first ask is the only chance.
      taps.openPending();

      expect(opened, hasLength(1));
    });

    test('it opens the reminder once, not again on every day read', () {
      phone.launchTap = _dose;
      dayRead = true;
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      taps.openPending();
      taps.openPending();

      expect(opened, hasLength(1));
    });

    test('a tap while the app runs opens the reminder at once', () async {
      dayRead = true;
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      phone.tapController.add(_dose);
      await pumpEventQueue();

      expect(opened.single.kind, TodayTaskKind.medication);
    });

    test('a tap during a slow or failed reading waits for the day', () async {
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      phone.tapController.add(_dose);
      await pumpEventQueue();
      expect(opened, isEmpty);

      dayRead = true;
      taps.openPending();

      expect(opened, hasLength(1));
    });

    test('«ذكّرني لاحقًا» puts the task off and opens nothing', () async {
      dayRead = true;
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      phone.tapController.add('$snoozeTapPrefix$_dose');
      await pumpEventQueue();

      expect(snoozed, <String>['$snoozeTapPrefix$_dose']);
      expect(opened, isEmpty);
    });

    test('the note that opens the app opens no reminder', () async {
      dayRead = true;
      final ReminderTaps taps = build();
      addTearDown(taps.dispose);

      phone.tapController.add(keepRemindersPayload);
      await pumpEventQueue();

      expect(opened, isEmpty);
    });
  });
}
