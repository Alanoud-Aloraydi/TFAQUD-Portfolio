import 'package:app/core/services/reminders/shared_snooze.dart';

/// Tells the server the task of [key] was put off [after] from now, so
/// the whole circle sees it and is reminded then. Offline, only this
/// phone knows; it reminds of it all the same.
Future<void> tellCircle(
  Future<void> Function(SnoozeShare snooze)? share,
  String key,
  Duration after,
) async {
  final SnoozeShare? snooze = snoozeShareOf(key, after);
  if (share == null || snooze == null) return;
  try {
    await share(snooze);
  } on Exception {
    // Offline, or recorded meanwhile: nothing more to do.
  }
}
