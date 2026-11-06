import 'package:shared_preferences/shared_preferences.dart';

/// Whether this install already showed the welcome pages.
///
/// The welcome shows once: after «ابدأ» or «تخطي», a signed-out phone opens
/// on the phone number page instead (after a sign-out, for example). It is
/// kept in the app's own storage, which goes with the app, so a reinstall
/// shows the welcome again. Nothing here goes to the server.
abstract final class IntroMemory {
  static const String _key = 'intro_seen';

  /// True once [markSeen] ran on this install. False when the storage
  /// cannot be read: showing the welcome again is the safe side.
  static Future<bool> seen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// The person finished or skipped the welcome.
  static Future<void> markSeen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Not saved: the welcome shows once more. Nothing else depends on it.
    }
  }
}
