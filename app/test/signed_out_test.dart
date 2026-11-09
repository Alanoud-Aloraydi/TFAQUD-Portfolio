import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _Reminders extends Fake implements DoseReminders {
  int clears = 0;

  @override
  Future<void> clear() async => clears++;
}

class _Calendar extends Fake implements CalendarSync {
  int clears = 0;

  @override
  Future<void> clear() async => clears++;
}

void main() {
  late _Reminders reminders;
  late _Calendar calendar;

  setUp(() {
    reminders = _Reminders();
    calendar = _Calendar();
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
}
