import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:get_it/get_it.dart';

/// Removes from this phone what belonged to the person whose sign-in ended
/// (a sign-out, an expired session, a deleted account), whichever mode they
/// used: their reminders, the events copied to the phone's calendar with
/// the choices behind them, and the names the app's words use. Every way
/// back to the sign-in pages calls it, so the next person on the phone
/// sees nothing of theirs.
Future<void> forgetSignedOutPerson() async {
  CareVoice.clear();
  await (
    GetIt.I<DoseReminders>().clear(),
    GetIt.I<CalendarSync>().clear(),
  ).wait;
}
