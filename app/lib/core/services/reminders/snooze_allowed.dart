import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/reminders/reminder_permission.dart';
import 'package:app/core/services/reminders/reminders_enabled.dart';

/// Whether a task put off with «ذكّرني لاحقًا» can come again on this
/// phone: the person still wants the reminders ([enabled]), and the phone
/// lets them through. With [ask], a phone never asked asks now and its
/// answer counts; without it, a phone never asked still counts as yes,
/// since putting the task off asks it.
Future<bool> remindersAllowed(
  RemindersEnabled enabled,
  ReminderPermission permission, {
  required bool ask,
}) async {
  if (!enabled.on.value) return false;
  final AppPermission allowed = await permission.ask(request: ask);
  return allowed.usable || (!ask && allowed == AppPermission.notAsked);
}
