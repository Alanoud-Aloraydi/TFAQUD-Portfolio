import 'package:app/core/services/permissions/app_permission.dart';

/// The word «حسابي» shows for [allowed], in both modes.
String notificationValueKey(AppPermission allowed) => switch (allowed) {
  AppPermission.granted => 'account.notifications_on',
  AppPermission.partial => 'account.notifications_partial',
  // Neither platform tells a refusal from a question not yet asked, so
  // this one means the app has never asked; it still can.
  AppPermission.notAsked => 'account.notifications_not_asked',
  AppPermission.denied => 'account.notifications_off',
};

/// Why the reminders cannot arrive properly, or null when they can.
/// «محدودة» is iOS «Deliver Quietly»: allowed, but with no alert and no
/// sound, which Settings is the only way out of.
String? notificationProblemKey(AppPermission allowed) => switch (allowed) {
  AppPermission.denied => 'circle_overview.notifications_denied',
  AppPermission.partial => 'account.notifications_quiet',
  _ => null,
};
