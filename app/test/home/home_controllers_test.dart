import 'package:app/core/services/phone_notifications.dart';
import 'package:app/core/services/reminders/reminder_payloads.dart';
import 'package:app/features/home/domain/entities/home_entity.dart';
import 'package:app/features/home/presentation/controllers/clinical_data_loader.dart';
import 'package:app/features/home/presentation/controllers/notification_tap_handler.dart';
import 'package:app/features/home/presentation/controllers/reminder_sync.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/home_fakes.dart';
import '../support/phone_fakes.dart';

void main() {
  group('ReminderSync', () {
    test('sets the phone once per list of circles, with each circle zone', () {
      final reminders = FakeDoseReminders();
      final calendar = FakeCalendarSync();
      final sync = ReminderSync(reminders, calendar);
      final data = homeData(
        circles: const [
          CareCircleSummary(id: 'one', name: 'One', timeZone: 'Europe/London'),
        ],
      );

      sync.onHome(data);
      sync.onHome(data);
      sync.onHome(homeData());

      expect(reminders.synced, hasLength(2));
      expect(calendar.synced, hasLength(2));
      expect(reminders.synced.first.single.timeZone, 'Europe/London');
      expect(reminders.synced.first.single.viewerId, 'account-a');
    });

    test('refresh asks both again', () {
      final reminders = FakeDoseReminders();
      final calendar = FakeCalendarSync();

      ReminderSync(reminders, calendar).refresh();

      expect(reminders.refreshes, 1);
      expect(calendar.refreshes, 1);
    });
  });

  group('occurrenceWindow', () {
    test('runs from yesterday to a month ahead, in calendar days', () {
      final window = occurrenceWindow(DateTime(2026, 11, 10));

      expect(window.from, DateTime(2026, 11, 9));
      expect(window.to, DateTime(2026, 12, 10));
    });

    test('crosses month and year ends and a clock change', () {
      expect(
        occurrenceWindow(DateTime(2026, 1, 1)).from,
        DateTime(2025, 12, 31),
      );
      expect(
        occurrenceWindow(DateTime(2026, 12, 15)).to,
        DateTime(2027, 1, 14),
      );
      // The day after a spring-forward day of many zones.
      expect(
        occurrenceWindow(DateTime(2026, 3, 29)).from,
        DateTime(2026, 3, 28),
      );
      expect(occurrenceWindow(DateTime(2026, 3, 29)).to, DateTime(2026, 4, 28));
    });
  });

  group('NotificationTapHandler', () {
    late FakePhoneNotifications phone;
    late FakeDoseReminders reminders;
    late bool ready;
    late List<String?> opened;
    late int snoozedMessages;
    late int inboxOpened;
    late NotificationTapHandler handler;

    NotificationTapHandler create() => NotificationTapHandler(
      phone,
      reminders,
      isReady: () => ready,
      openToday: opened.add,
      openInbox: () => inboxOpened++,
      onSnoozed: () => snoozedMessages++,
    );

    setUp(() {
      phone = FakePhoneNotifications();
      reminders = FakeDoseReminders();
      ready = true;
      opened = <String?>[];
      snoozedMessages = 0;
      inboxOpened = 0;
    });

    tearDown(() => handler.dispose());

    test('a reminder tap opens «اليوم» of its circle', () async {
      handler = create();

      phone.tapController.add('${doseReminderPayload}circle-1');
      await Future<void>.delayed(Duration.zero);

      expect(opened, ['circle-1']);
    });

    test('the note to open the app opens «اليوم» with no circle', () async {
      handler = create();

      phone.tapController.add(keepRemindersPayload);
      await Future<void>.delayed(Duration.zero);

      expect(opened, [null]);
    });

    test(
      'a push about an invitation or a request opens the notifications',
      () async {
        handler = create();

        phone.tapController.add('${pushTapPrefix}invitation');
        phone.tapController.add('${pushTapPrefix}circle_request');
        await Future<void>.delayed(Duration.zero);

        expect(inboxOpened, 2);
        expect(opened, isEmpty);
      },
    );

    test('any other push opens «اليوم» as it is', () async {
      handler = create();

      phone.tapController.add('${pushTapPrefix}dose_missed');
      await Future<void>.delayed(Duration.zero);

      expect(opened, [null]);
      expect(inboxOpened, 0);
    });

    test('a push that launched the app is opened once ready', () {
      phone.launchTap = '${pushTapPrefix}invitation';
      ready = false;
      handler = create();
      expect(inboxOpened, 0);

      handler.onReady();

      expect(inboxOpened, 1);
    });

    test('a tap before the home data is ready waits for it', () async {
      ready = false;
      handler = create();

      phone.tapController.add('${doseReminderPayload}circle-2');
      await Future<void>.delayed(Duration.zero);
      expect(opened, isEmpty);

      ready = true;
      handler.onReady();
      handler.onReady();
      expect(opened, ['circle-2']);
    });

    test('the tap that launched the app is opened once ready', () {
      phone.launchTap = '${doseReminderPayload}circle-3';
      ready = false;
      handler = create();
      expect(opened, isEmpty);

      handler.onReady();

      expect(opened, ['circle-3']);
    });

    test(
      '«ذكّرني لاحقًا» sets the reminder again, says so, and stays',
      () async {
        ready = false;
        handler = create();
        final String tap = '$snoozeTapPrefix${doseSnoozePayload}circle-1';

        phone.tapController.add(tap);
        await Future<void>.delayed(Duration.zero);

        expect(reminders.snoozed, [tap]);
        expect(snoozedMessages, 1);
        expect(opened, isEmpty);
      },
    );

    test('a snooze that did not happen says nothing', () async {
      reminders.result = false;
      handler = create();

      phone.tapController.add('$snoozeTapPrefix${doseSnoozePayload}circle-1');
      await Future<void>.delayed(Duration.zero);

      expect(snoozedMessages, 0);
    });

    test('after dispose a tap does nothing', () async {
      handler = create();
      handler.dispose();

      phone.tapController.add('${doseReminderPayload}circle-1');
      await Future<void>.delayed(Duration.zero);

      expect(opened, isEmpty);
    });
  });
}
