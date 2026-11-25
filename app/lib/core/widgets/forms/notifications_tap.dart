import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/permissions/ask_notifications.dart';
import 'package:app/core/widgets/forms/leave_for_settings.dart';
import 'package:app/core/widgets/forms/permission_confirm.dart';
import 'package:flutter/material.dart';

/// A tap on the notifications switch, in both modes.
///
/// Locked in the phone's Settings: the switch does not move; a word, then
/// the Settings. Turned on: what the reminders are for, as the calendar's
/// switch says it, then the phone's own question when it was never asked.
/// Turned off: off at once, and nothing more comes (askNotifications).
Future<void> tapNotifications(
  BuildContext context,
  AppPermission allowed, {
  required bool wanted,
}) async {
  if (notificationsNeedSettings(allowed)) {
    await leaveForSettings(
      context,
      'account.notifications_opening',
      failedKey: 'account.notifications_settings_failed',
    );
    return;
  }
  if (wanted &&
      !await confirmPermission(context, 'account.notifications_confirm')) {
    return;
  }
  await askNotifications(allowed, wanted: wanted);
}
