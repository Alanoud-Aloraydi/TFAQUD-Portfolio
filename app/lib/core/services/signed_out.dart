import 'package:app/core/l10n/care_voice.dart';
import 'package:app/core/services/calendar_sync.dart';
import 'package:app/core/services/remote_push.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:get_it/get_it.dart';

/// Removes from this phone what belonged to the person whose sign-in ended
/// (a sign-out, an expired session, a deleted account), whichever mode they
/// used: their reminders, the events copied to the phone's calendar with
/// the choices behind them, the names the app's words use, and the
/// account's tie to the server's pushes (OneSignal). Every way
/// back to the sign-in pages calls it, so the next person on the phone
/// sees nothing of theirs.
Future<void> forgetSignedOutPerson() async {
  CareVoice.clear();
  await (
    GetIt.I<DoseReminders>().clear(),
    GetIt.I<CalendarSync>().clear(),
    _untieRemotePush(),
  ).wait;
}

/// OneSignal stops sending the account's pushes here; a failure (no
/// network) leaves it for the next sign-in to replace.
Future<void> _untieRemotePush() async {
  try {
    await GetIt.I<RemotePush>().signOut();
  } on Exception {
    // Nothing to do: the next account's sign-in takes this phone over.
  }
}
