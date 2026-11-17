import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:get_it/get_it.dart';

/// Whether a tap on the notifications switch has to leave for the phone's
/// Settings: the phone refuses the reminders and has been asked already,
/// and iOS gives no way back from a refusal inside the app.
bool notificationsNeedSettings(AppPermission allowed) =>
    !allowed.usable && allowed != AppPermission.notAsked;

/// What a tap on the notifications switch does once Settings is not the
/// answer ([notificationsNeedSettings]), in both modes.
///
/// Two answers stand behind the one switch: whether the phone lets the
/// reminders through, and whether the person still wants them. While the
/// phone has never been asked, the tap asks it. Once the phone allows
/// them, the switch is the person's own and turns the reminders off and
/// on here.
Future<void> askNotifications(
  AppPermission allowed, {
  required bool wanted,
}) async {
  final DoseReminders reminders = GetIt.I<DoseReminders>();
  if (allowed.usable) {
    await reminders.enabled.set(wanted);
  } else {
    await reminders.requestPermission();
  }
}
