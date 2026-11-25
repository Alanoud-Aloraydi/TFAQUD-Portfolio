import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the server sends this phone the reminders at the tasks' times,
/// as its answer to the phone's push subscription last said (backend
/// `app/push/scheduled/reminders`).
///
/// While it does, the phone sets none of its own, so nobody is reminded
/// twice. The server reads the plan at each reminder's moment, so a change
/// someone else made reaches this phone even when the app was not opened.
/// A task put off from this phone still comes again from the phone itself.
///
/// Kept on the phone, so an app opened without a network goes on as the
/// server last said. Off until the server says so: a server from before,
/// or one with its switch off, leaves the reminders to the phone.
class ServerReminders {
  static const String _key = 'server_reminders';

  /// Off until [read] or the server says otherwise.
  final ValueNotifier<bool> on = ValueNotifier<bool>(false);

  /// Whether the server answered since the app started: its answer wins
  /// over the one [read] finds kept.
  bool _answered = false;

  Future<void> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!_answered) on.value = prefs.getBool(_key) ?? false;
  }

  /// Keeps the server's answer; a change plans the reminders again.
  Future<void> set(bool value) async {
    _answered = true;
    on.value = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

/// Whether the server's [answer] to the phone's push subscription says it
/// sends this phone the reminders. A server from before answers nothing.
bool serverRemindsFrom(Object? answer) =>
    answer is Map && answer['server_reminders'] == true;
