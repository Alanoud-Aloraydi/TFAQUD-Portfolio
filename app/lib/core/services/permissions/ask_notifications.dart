import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/app_settings_page.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:get_it/get_it.dart';

/// Whether a tap on the notifications switch has to leave for the phone's
/// Settings: the phone refuses the reminders and has been asked already,
/// and iOS gives no way back from a refusal inside the app.
bool notificationsNeedSettings(AppPermission allowed) =>
    !allowed.usable && allowed != AppPermission.notAsked;

/// What a tap on the notifications switch does, in both modes.
///
/// Two answers stand behind the one switch: whether the phone lets the
/// reminders through, and whether the person still wants them. While the
/// phone does not let them through there is nothing to want, so the tap
/// goes after the permission — the phone's own question the first time,
/// its Settings every time after. Once the phone allows them, the switch
/// is the person's own and turns the reminders off and on here.
///
/// False only when the Settings page did not open, so the page that owns
/// the switch can say so instead of looking broken.
Future<bool> askNotifications(
  AppPermission allowed, {
  required bool wanted,
}) async {
  final DoseReminders reminders = GetIt.I<DoseReminders>();
  if (allowed.usable) {
    await reminders.enabled.set(wanted);
    return true;
  }
  if (allowed == AppPermission.notAsked) {
    await reminders.requestPermission();
    return true;
  }
  return openAppSettingsPage();
}
