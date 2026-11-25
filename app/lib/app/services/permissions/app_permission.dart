import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the phone allows the app to do with one of its features, read from
/// the system and never from a saved choice of ours: the person can change
/// it in the phone's Settings while the app is away.
enum AppPermission {
  /// Never asked yet, so asking still shows the system's question.
  notAsked,

  /// Allowed in full.
  granted,

  /// Allowed in part. On iOS the calendar can be «Add Only»: the app writes
  /// events but cannot delete the ones it no longer wants.
  partial,

  /// Refused. iOS asks only once, so the person must change it in Settings.
  denied;

  /// Whether the feature works at all with this answer.
  bool get usable => this == granted || this == partial;

  /// Whether asking would still show the system's question.
  bool get askable => this == notAsked || this == partial;
}

/// Opens this app's own page in the phone's Settings, where a refused
/// permission is turned back on. iOS allows no deeper link than the app's
/// page, so the person taps the permission there themselves.
Future<bool> openAppSettingsPage() => appSettingsOpener();

/// What [openAppSettingsPage] calls. A widget test has no Settings page and
/// no plugin to answer, so it puts its own here and counts the calls.
@visibleForTesting
Future<bool> Function() appSettingsOpener = _launchSettings;

Future<bool> _launchSettings() async {
  try {
    return await launchUrl(Uri.parse('app-settings:'));
  } on Exception catch (error) {
    debugPrint('The Settings page did not open: $error');
    return false;
  }
}
