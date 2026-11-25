import 'dart:async';

import 'package:app/app/services/permissions/app_permission.dart';
import 'package:app/app/services/permissions/notification_words.dart';
import 'package:app/app/services/reminders/dose_reminders.dart';
import 'package:app/core/widgets/forms/permission_confirm.dart';
import 'package:app/core/widgets/layout/inset_text.dart';
import 'package:app/core/widgets/layout/section_title.dart';
import 'package:app/core/widgets/layout/settings_icon_tile.dart';
import 'package:app/features/account/presentation/widgets/notification_state_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// «تنبيهات الجوال» in «حسابي»: whether the phone lets the reminders
/// arrive, and the way to Settings when it does not. The calendar card
/// showed the refusal before, which buried it under another feature and
/// hid it from anyone with no circle yet.
class AccountNotificationsCard extends StatefulWidget {
  const AccountNotificationsCard({super.key});

  @override
  State<AccountNotificationsCard> createState() =>
      _AccountNotificationsCardState();
}

class _AccountNotificationsCardState extends State<AccountNotificationsCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Read it now: nothing may have scheduled a reminder yet, and the
    // state is null until something asks. Read it again on the way back
    // from Settings, where the answer is the one thing that can change.
    _refresh();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
  }

  void _refresh() => unawaited(GetIt.I<DoseReminders>().refreshPermission());

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SectionTitle(context.tr('account.notifications_title')),
      ValueListenableBuilder<AppPermission?>(
        valueListenable: GetIt.I<DoseReminders>().allowed,
        builder: (BuildContext context, AppPermission? allowed, Widget? _) =>
            allowed == null
            ? const SizedBox.shrink()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SettingsCard(
                    children: <Widget>[NotificationStateRow(allowed: allowed)],
                  ),
                  NotificationNote(allowed: allowed),
                ],
              ),
      ),
    ],
  );
}

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
