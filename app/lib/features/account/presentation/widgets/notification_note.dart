import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/notification_words.dart';
import 'package:app/core/widgets/forms/permission_denied_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// What sits under the notifications row: the way out of a refusal or of
/// «Deliver Quietly», the question itself while it has never been asked,
/// or the line that says what the reminders are for.
class NotificationNote extends StatelessWidget {
  const NotificationNote({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) {
    final String? problem = notificationProblemKey(allowed);
    if (problem != null) return PermissionDeniedRow(messageKey: problem);
    return InsetText.note(context.tr('account.notifications_hint'));
  }
}
