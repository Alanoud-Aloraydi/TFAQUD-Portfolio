import 'dart:async';

import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/notification_words.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_button.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_permission_denied.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// What sits under the notifications row at this mode's sizes: the way
/// out of a refusal or of «Deliver Quietly», the question itself while it
/// has never been asked, or the line that says what the reminders do.
class SimplifiedNotificationsNote extends StatelessWidget {
  const SimplifiedNotificationsNote({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) {
    final String? problem = notificationProblemKey(allowed);
    if (problem != null) {
      return SimplifiedPermissionDenied(messageKey: problem);
    }
    if (allowed == AppPermission.notAsked) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SimplifiedButton(
          label: context.tr('account.notifications_enable'),
          onPressed: () =>
              unawaited(GetIt.I<DoseReminders>().requestPermission()),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: 8,
        start: SimplifiedStyle.pad,
        end: SimplifiedStyle.pad,
      ),
      child: Text(
        context.tr('account.notifications_hint'),
        style: SimplifiedStyle.text(SimplifiedStyle.caption),
      ),
    );
  }
}
