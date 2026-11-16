import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/notification_words.dart';
import 'package:app/core/widgets/layout/inset_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Whether the phone lets the reminders arrive: «مفعّلة», «محدودة» when
/// iOS keeps them quiet in the notification centre, or «مقفلة». The word
/// carries the state, never a colour on its own.
class NotificationStateRow extends StatelessWidget {
  const NotificationStateRow({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) => InsetRow(
    label: context.tr('account.notifications_row'),
    value: context.tr(notificationValueKey(allowed)),
  );
}
