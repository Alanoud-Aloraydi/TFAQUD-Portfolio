import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/services/permissions/app_settings_page.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// What a switch does when the phone refused its permission before: iOS
/// asks only once, so the way back is the phone's Settings. A switch that
/// quietly leaves the app reads as broken, so [wordsKey] says where it is
/// going, for [AppMotion.settingsLead], before it leaves; and when the
/// Settings page does not open, [failedKey] says so.
Future<void> leaveForSettings(
  BuildContext context,
  String wordsKey, {
  required String failedKey,
}) async {
  // Taken before the await: the app leaves for Settings in between.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String failed = context.tr(failedKey);
  AppToast.showText(messenger, context.tr(wordsKey));
  await Future<void>.delayed(AppMotion.settingsLead);
  if (!await openAppSettingsPage()) {
    AppToast.showText(messenger, failed, kind: ToastKind.error);
  }
}
