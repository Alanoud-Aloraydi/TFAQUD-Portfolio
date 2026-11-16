import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens this app's own page in the phone's Settings, where a refused
/// permission is turned back on. iOS allows no deeper link than the app's
/// page, so the person taps the permission there themselves.
Future<bool> openAppSettingsPage() async {
  try {
    return await launchUrl(Uri.parse('app-settings:'));
  } on Exception catch (error) {
    debugPrint('The Settings page did not open: $error');
    return false;
  }
}
