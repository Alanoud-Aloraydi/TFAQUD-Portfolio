import 'package:app/core/feedback/app_toast.dart';
import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/ask_notifications.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A tap on the notifications switch, with a word for what it is doing.
///
/// A switch that quietly sends the person to the phone's Settings, or that
/// does nothing at all because the Settings page refused to open, reads as
/// a broken switch; so the leaving is said before it happens, and the
/// failure after it.
Future<void> tapNotifications(
  BuildContext context,
  AppPermission allowed, {
  required bool wanted,
}) async {
  // Taken before the await: the app leaves for Settings in between.
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String leaving = context.tr('account.notifications_opening');
  final String failed = context.tr('account.notifications_settings_failed');
  if (notificationsNeedSettings(allowed)) {
    AppToast.showText(messenger, leaving);
  }
  if (!await askNotifications(allowed, wanted: wanted)) {
    AppToast.showText(messenger, failed, kind: ToastKind.error);
  }
}
