export 'package:app/core/services/leftover_sign_in.dart';

import 'dart:async';
import 'dart:io';

import 'package:app/core/services/leftover_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this start is the first one of a new install of the app.
///
/// iOS gives an app no word when it is deleted. It deletes the app's own
/// files and preferences with it, but keeps what the app put in the
/// Keychain: the session tokens. So deleting the app and installing it again
/// would open signed in as before. The first start of an install finds that
/// out here, and [LeftoverSignIn] signs that sign-in out.
abstract final class FreshInstall {
  /// Written at the first start; it goes when the app is deleted.
  static const String _markKey = 'install_started';

  /// The file GetStorage makes at every start, since the app's first build
  /// (core/setup.dart). An update from a build older than [_markKey] has it;
  /// a new install does not, yet.
  static const String _olderBuildsFile = 'GetStorage.gs';

  static bool _firstStart = false;

  /// Whether [check] found this start to be the first of a new install.
  static bool get firstStart => _firstStart;

  /// Finds out once, at the start, before `GetStorage.init` (which makes
  /// [_olderBuildsFile]). When it cannot tell, the start is not counted as
  /// a first one: no one is signed out by mistake.
  static Future<void> check({
    Future<bool> Function()? olderBuildStarted,
  }) async {
    _firstStart = false;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_markKey) ?? false) return;
      final bool updated = await (olderBuildStarted ?? _olderBuildStarted)();
      await prefs.setBool(_markKey, true);
      _firstStart = !updated;
    } catch (_) {
      // Unknown: as a start like any other.
    }
  }

  static Future<bool> _olderBuildStarted() async {
    final Directory documents = await getApplicationDocumentsDirectory();
    return File('${documents.path}/$_olderBuildsFile').exists();
  }
}
