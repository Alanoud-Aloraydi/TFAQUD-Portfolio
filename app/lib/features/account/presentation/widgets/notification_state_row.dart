import 'dart:async';

import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/notification_words.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/widgets/forms/notifications_tap.dart';
import 'package:app/core/widgets/layout/toggle_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// The notifications switch, the same shape as the calendar rows above it.
///
/// On means both answers are yes: the phone lets the reminders through and
/// the person still wants them. Off while the phone refuses leads to its
/// Settings; off while the phone allows is the person's own choice and
/// takes the planned reminders off.
class NotificationStateRow extends StatelessWidget {
  const NotificationStateRow({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: GetIt.I<DoseReminders>().enabled.on,
    builder: (BuildContext context, bool wanted, Widget? _) => ToggleRow(
      label: context.tr('account.notifications_row'),
      hint: context.tr(notificationStateKey(allowed, wanted: wanted)),
      value: allowed.usable && wanted,
      onChanged: (bool value) =>
          unawaited(tapNotifications(context, allowed, wanted: value)),
    ),
  );
}
