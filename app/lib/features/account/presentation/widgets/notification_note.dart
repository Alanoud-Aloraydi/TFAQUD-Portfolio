import 'dart:async';

import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/notification_words.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/widgets/forms/permission_denied_row.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

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
    if (allowed == AppPermission.notAsked) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.inset),
        child: TextButton(
          onPressed: () =>
              unawaited(GetIt.I<DoseReminders>().requestPermission()),
          child: Text(context.tr('account.notifications_enable')),
        ),
      );
    }
    return InsetText.note(context.tr('account.notifications_hint'));
  }
}
