import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:app/core/widgets/forms/notifications_tap.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_switch_row.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:app/core/theme/app_settings_tile_colors.dart';

/// The notifications switch at this mode's sizes, beside a green bell.
///
/// On means the phone lets the reminders through and the person still
/// wants them; see [toggleNotifications] for what a tap does.
class SimplifiedNotificationsSwitch extends StatelessWidget {
  const SimplifiedNotificationsSwitch({super.key, required this.allowed});

  final AppPermission allowed;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: GetIt.I<DoseReminders>().enabled.on,
    builder: (BuildContext context, bool wanted, Widget? _) =>
        SimplifiedSwitchRow(
          icon: NoticeIcons.bell,
          background: AppSettingsTileColors.doses,
          label: context.tr('account.notifications_row'),
          value: allowed.usable && wanted,
          onChanged: (bool value) =>
              unawaited(tapNotifications(context, allowed, wanted: value)),
        ),
  );
}
