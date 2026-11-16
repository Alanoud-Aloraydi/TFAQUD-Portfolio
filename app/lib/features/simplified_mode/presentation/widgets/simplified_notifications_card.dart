import 'dart:async';

import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/permissions/notification_words.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_card.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_medical_file_row.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_notifications_note.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_style.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

/// «تنبيهات الجوال» in this mode's «حسابي»: whether the reminders can
/// arrive, and the way to Settings when they cannot. Shown to every
/// patient, with a circle or without: the refusal used to hang under the
/// calendar title, where a patient with no circle never saw it.
class SimplifiedNotificationsCard extends StatefulWidget {
  const SimplifiedNotificationsCard({super.key});

  @override
  State<SimplifiedNotificationsCard> createState() =>
      _SimplifiedNotificationsCardState();
}

class _SimplifiedNotificationsCardState
    extends State<SimplifiedNotificationsCard> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Nothing may have scheduled a reminder yet, so read it now; and read
    // it again coming back from Settings, where it can change.
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
  Widget build(BuildContext context) => ValueListenableBuilder<AppPermission?>(
    valueListenable: GetIt.I<DoseReminders>().allowed,
    builder: (BuildContext context, AppPermission? allowed, Widget? _) =>
        allowed == null ? const SizedBox.shrink() : _state(context, allowed),
  );

  Widget _state(BuildContext context, AppPermission allowed) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      SimplifiedCard(
        padding: const EdgeInsets.symmetric(horizontal: SimplifiedStyle.pad),
        child: SimplifiedMedicalFileRow(
          label: context.tr('account.notifications_row'),
          value: context.tr(notificationValueKey(allowed)),
          last: true,
        ),
      ),
      SimplifiedNotificationsNote(allowed: allowed),
    ],
  );
}
