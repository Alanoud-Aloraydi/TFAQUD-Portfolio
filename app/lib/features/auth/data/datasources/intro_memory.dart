import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The welcome flag, kept in the app's own storage on this phone, which
/// goes with the app: a reinstall shows the welcome again.
class IntroMemory implements WelcomeMemory {
  static const String _key = 'intro_seen';

  /// True once [markSeen] ran on this install. False when the storage
  /// cannot be read: showing the welcome again is the safe side.
  @override
  Future<bool> seen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// The person finished or skipped the welcome.
  @override
  Future<void> markSeen() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (_) {
      // Not saved: the welcome shows once more. Nothing else depends on it.
    }
  }
}
