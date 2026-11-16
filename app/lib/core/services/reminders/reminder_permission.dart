import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/phone_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the phone allows the reminders to do, kept in one place so the
/// reminders themselves hold only the asking, never the answer.
///
/// Neither platform tells «not asked yet» from «refused»: Android's
/// `areNotificationsEnabled` and iOS's `checkPermissions` both answer
/// false before the question and after a no. So this remembers whether
/// this install has ever asked, and only calls a false answer a refusal
/// once it has. The difference matters: a refusal is undone in Settings,
/// while a question not yet asked is answered by the app itself.
class ReminderPermission {
  ReminderPermission(this._phone);

  static const String _askedKey = 'reminders.permission.asked';

  final PhoneNotifications _phone;
  final ValueNotifier<AppPermission?> _value = ValueNotifier<AppPermission?>(
    null,
  );

  /// The last answer; null until the first ask or read. Both modes watch
  /// it, so a person whose notifications are off is told instead of
  /// waiting for reminders that cannot arrive.
  ValueListenable<AppPermission?> get value => _value;

  /// The phone's answer as it stands, without asking for it.
  Future<AppPermission> read() => ask(request: false);

  /// Asks the phone, or reads what it already answered, and publishes it.
  Future<AppPermission> ask({required bool request}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (request) {
      await _phone.requestPermission();
      await prefs.setBool(_askedKey, true);
    }
    final AppPermission answer = await _phone.permission();
    // A yes is proof the question was asked, whoever asked it: installs
    // from before this flag existed have none, and would otherwise read
    // as never asked.
    if (answer.usable) await prefs.setBool(_askedKey, true);
    final bool asked = prefs.getBool(_askedKey) ?? false;
    // A no that was never asked for is a question still to come.
    _value.value = answer == AppPermission.denied && !asked
        ? AppPermission.notAsked
        : answer;
    return _value.value!;
  }
}
