import 'package:app/app/services/phone_notifications.dart';
import 'package:app/app/services/push_target.dart';
import 'package:app/app/services/reminders/item_keys.dart';
import 'package:app/app/services/reminders/reminder_payloads.dart';
import 'package:app/app/services/reminders/tapped_item.dart';
import 'package:app/app/services/tap_focus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('a push names its item', () {
    test('a dose by its circle, schedule and day, as its snooze key', () {
      expect(
        pushTapText(<String, dynamic>{
          'kind': 'dose_missed',
          'circle_id': 'c-1',
          'schedule_id': 's-1',
          'scheduled_on': '2026-11-05',
        }),
        'dose_missed${pushItemSeparator}c-1|s-1|2026-11-5',
      );
    });

    test('a reading time by its version, time and day', () {
      expect(
        pushItemKey(<String, dynamic>{
          'kind': 'measurement_snoozed',
          'circle_id': 'c-1',
          'plan_version_id': 'v-1',
          'scheduled_on': '2026-11-15',
          'time_of_day': '08:00',
        }),
        'c-1|measurement|v-1|08:00|2026-11-15',
      );
    });

    test('a visit, an invitation, a request, an answer and a circle', () {
      expect(
        pushItemKey(<String, dynamic>{
          'kind': 'appointment_missed',
          'circle_id': 'c-1',
          'appointment_id': 'a-1',
        }),
        appointmentItemKey('c-1', 'a-1'),
      );
      expect(
        pushItemKey(<String, dynamic>{
          'kind': 'invitation',
          'invitation_id': 'i-1',
        }),
        inboxItemKey('i-1'),
      );
      expect(
        pushItemKey(<String, dynamic>{
          'kind': 'circle_request',
          'request_id': 'r-1',
        }),
        inboxItemKey('r-1'),
      );
      expect(
        pushItemKey(<String, dynamic>{
          'kind': 'request_answer',
          'request_id': 'r-1',
        }),
        answeredItemKey('r-1'),
      );
      expect(
        pushItemKey(<String, dynamic>{
          'kind': 'circle_ready',
          'circle_id': 'c-2',
        }),
        'c-2',
      );
    });

    test("a reminder from the server is tapped as the phone's own", () {
      const String payload = 'dose:c-1\u001Ftitle\u001Fbody\u001Fkey\u001Fname';
      final Map<String, dynamic> data = <String, dynamic>{
        'kind': 'dose_reminder',
        'circle_id': 'c-1',
        'reminder': payload,
      };
      expect(pushTapText(data), '$serverReminderTapPrefix$payload');
      // «ذكّرني لاحقًا» on it puts that task off.
      expect(
        pushTapText(data, action: snoozeAction),
        '$serverReminderTapPrefix$snoozeTapPrefix$payload',
      );
    });

    test('an older push has its kind only, and no kind is nothing', () {
      expect(
        pushTapText(<String, dynamic>{'kind': 'invitation'}),
        'invitation',
      );
      expect(pushTapText(<String, dynamic>{}), isNull);
      expect(pushTapText(null), isNull);
    });
  });

  test('the kind and the item of a tapped push are read apart', () {
    const String tap =
        '${pushTapPrefix}dose_missed${pushItemSeparator}c-1|s-1|2026-11-5';
    expect(pushKind(tap), 'dose_missed');
    expect(pushTapItem(tap), 'c-1|s-1|2026-11-5');
    expect(pushTapItem('${pushTapPrefix}invitation'), isNull);
    expect(pushTapItem('${doseReminderPayload}c-1'), isNull);
  });

  test('an invitation, a request and a declined answer open the bell', () {
    expect(opensBell('invitation', null), isTrue);
    expect(opensBell('circle_request', inboxItemKey('r-1')), isTrue);
    expect(opensBell('request_answer', answeredItemKey('r-1')), isTrue);
    // Accepted: it waits for the patient, with no card on the bell yet.
    expect(opensBell('request_answer', null), isFalse);
    // A request that can no longer be accepted: its card in «السابقة».
    expect(opensBell('request_superseded', answeredItemKey('r-1')), isTrue);
    expect(opensBell('dose_missed', 'c-1|s-1|2026-11-5'), isFalse);
    expect(opensBell(null, null), isFalse);
  });

  group('a tapped reminder names its item', () {
    test('a dose by its snooze key', () {
      final String payload = payloadWithText(
        '${doseReminderPayload}c-1',
        'title',
        'body',
        snoozeKey: 'c-1|s-1|2026-11-5',
        subject: 'ميتفورمين',
      );
      expect(tappedItemKey(payload), 'c-1|s-1|2026-11-5');
    });

    test('a visit by the id after its circle', () {
      const String payload =
          '${appointmentReminderPayload}c-1${appointmentIdMark}v-1';
      expect(tappedItemKey(payload), appointmentItemKey('c-1', 'v-1'));
      expect(reminderCircleId(payload), 'c-1');
    });

    test('the note and an older visit reminder name none', () {
      expect(tappedItemKey(keepRemindersPayload), isNull);
      expect(tappedItemKey('${appointmentReminderPayload}c-1'), isNull);
    });
  });

  test('an item of «اليوم» has a circle, one of the bell has none', () {
    expect(itemCircleId('c-1|s-1|2026-11-5'), 'c-1');
    expect(itemCircleId(appointmentItemKey('c-1', 'v-1')), 'c-1');
    expect(itemCircleId(inboxItemKey('r-1')), isNull);
    expect(itemCircleId(answeredItemKey('r-1')), isNull);
    expect(itemCircleId(null), isNull);
    expect(isAnsweredItem(answeredItemKey('r-1')), isTrue);
    expect(isAnsweredItem(inboxItemKey('r-1')), isFalse);
  });

  test('a tapped item is brought into view once, within two minutes', () {
    DateTime now = DateTime(2026, 11, 15, 10);
    final TapFocus focus = TapFocus(now: () => now);

    focus.show('c-1|a');
    expect(focus.waiting, 'c-1|a');
    expect(focus.claim('c-1|b'), isFalse);
    expect(focus.claim('c-1|a'), isTrue);
    expect(focus.claim('c-1|a'), isFalse);
    expect(focus.waiting, isNull);
    // Its prayer period stays open.
    expect(focus.key, 'c-1|a');

    focus.show('c-1|a');
    now = now.add(const Duration(minutes: 3));
    expect(focus.waiting, isNull);
    expect(focus.claim('c-1|a'), isFalse);
  });
}
