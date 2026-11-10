import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../support/phone_fakes.dart';

void main() {
  group('SignedOut', () {
    late FakeDoseReminders reminders;
    late FakeCalendarSync calendar;

    setUp(() {
      reminders = FakeDoseReminders();
      calendar = FakeCalendarSync();
      GetIt.I
        ..registerSingleton<DoseReminders>(reminders)
        ..registerSingleton<CalendarSync>(calendar);
    });

    tearDown(() => GetIt.I.reset());

    test('the next person on the phone finds nothing of the last one: no '
        'reminders, no calendar events, no names', () async {
      CareVoice.viewerName = 'مريم';
      CareVoice.update(<String, String?>{'c-1': 'نورة'});

      await forgetSignedOutPerson();

      expect(reminders.clears, 1);
      expect(calendar.clears, 1);
      expect(CareVoice.viewerName, isNull);
      expect(CareVoice.patientOf('c-1'), isNull);
    });
  });
}
