import 'package:app/app/services/calendar_sync.dart';
import 'package:app/app/services/push_registration.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/app/services/remote_push.dart';
import 'package:app/app/services/signed_out.dart';
import 'package:app/core/localization/care_voice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../support/phone_fakes.dart';

void main() {
  group('SignedOut', () {
    late FakeDoseReminders reminders;
    late FakeCalendarSync calendar;
    late FakeRemotePush remote;

    setUp(() {
      reminders = FakeDoseReminders();
      calendar = FakeCalendarSync();
      remote = FakeRemotePush();
      GetIt.I
        ..registerSingleton<DoseReminders>(reminders)
        ..registerSingleton<CalendarSync>(calendar)
        ..registerSingleton<RemotePush>(remote);
    });

    tearDown(() => GetIt.I.reset());

    test('the next person on the phone finds nothing of the last one: no '
        'reminders, no calendar events, no names, no pushes', () async {
      CareVoice.viewerName = 'مريم';
      CareVoice.update(<String, String?>{'c-1': 'نورة'});

      await forgetSignedOutPerson();

      expect(reminders.clears, 1);
      expect(calendar.clears, 1);
      expect(remote.signOuts, 1);
      expect(CareVoice.viewerName, isNull);
      expect(CareVoice.patientOf('c-1'), isNull);
    });

    test('no subscription is sent for the sign-in that ended', () async {
      final List<String> sent = <String>[];
      final PushRegistration push = PushRegistration(
        FakePhoneNotifications(),
        remote: remote,
        send: (String id) async => sent.add(id),
      );
      GetIt.I.registerSingleton<PushRegistration>(push);
      await push.start(accountId: 'acc-1');

      await forgetSignedOutPerson();
      remote.register('sub-1');
      await Future<void>.delayed(Duration.zero);

      expect(sent, isEmpty);
      expect(remote.observers, isEmpty);
    });
  });
}
