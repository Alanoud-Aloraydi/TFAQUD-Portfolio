import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this phone wants the reminders at all, kept by the app itself.
///
/// iOS gives no way to hand an allowed permission back, so the switch in
/// «حسابي» would have nothing to turn off without this: the permission
/// says the phone *may* show the reminders, this says the person still
/// wants them. Off takes every planned reminder off the phone and keeps
/// new ones from being planned; on plans them again.
///
/// On by default: someone who allowed the permission asked for them.
class RemindersEnabled {
  static const String _key = 'reminders_enabled';

  /// On until [read] says otherwise, so the first reading plans nothing
  /// the person turned off.
  final ValueNotifier<bool> on = ValueNotifier<bool>(true);

  Future<void> read() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    on.value = prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    if (on.value == value) return;
    on.value = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
