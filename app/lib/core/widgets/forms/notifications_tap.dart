import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/ask_notifications.dart';
import 'package:app/core/widgets/forms/leave_for_settings.dart';
import 'package:app/core/widgets/forms/permission_confirm.dart';
import 'package:flutter/material.dart';

/// A tap on the notifications switch, in both modes.
///
/// Refused before: the word, then the phone's Settings. Never asked: what
/// the reminders are for, then the phone's own question. Allowed: the
/// person's own choice, kept here.
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
  if (allowed == AppPermission.notAsked &&
      !await confirmPermission(context, 'account.notifications_confirm')) {
    return;
  }
  await askNotifications(allowed, wanted: wanted);
}
