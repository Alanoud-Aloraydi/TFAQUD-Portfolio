import 'package:app/core/services/permissions/app_permission.dart';
import 'package:app/core/services/reminders/dose_reminders.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';

/// Shows [row] only while the phone refuses notifications, so a person
/// whose reminders cannot arrive is told instead of waiting for them. Each
/// mode passes its own row.
class NotificationsDeniedWatcher extends StatelessWidget {
  const NotificationsDeniedWatcher({super.key, required this.row});

  final Widget row;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<AppPermission?>(
    valueListenable: GetIt.I<DoseReminders>().allowed,
    builder: (BuildContext context, AppPermission? allowed, Widget? _) =>
        allowed == null || allowed.usable ? const SizedBox.shrink() : row,
  );
}
