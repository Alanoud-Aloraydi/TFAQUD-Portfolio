import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:flutter/foundation.dart';

/// What the phone allows the reminders to do, as [DoseReminders] gives it.
mixin ReminderPermissions {
  @protected
  ReminderPermission get permission;

  /// What the phone allows the reminders to do; see [ReminderPermission].
  ValueListenable<AppPermission?> get allowed => permission.value;

  /// The phone's answer as it stands, without asking for it.
  Future<AppPermission> refreshPermission() => permission.read();

  /// Puts the phone's own question, which iOS shows only the first time.
  Future<AppPermission> requestPermission() => permission.ask(request: true);
}
