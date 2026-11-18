import 'package:app/core/widgets/navigation/glass_segmented_control.dart';
import 'package:app/features/circles/presentation/notifications_tab.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The two tabs of the notifications page, «الحالية» and «السابقة».
class NotificationsTabs extends StatelessWidget {
  const NotificationsTabs({
    super.key,
    required this.selected,
    required this.needsReply,
    required this.onChanged,
  });

  final NotificationsTab selected;
  final int needsReply;
  final ValueChanged<NotificationsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassSegmentedControl<NotificationsTab>(
      segments: <NotificationsTab, String>{
        NotificationsTab.current: context.tr('circles.tab_current'),
        NotificationsTab.previous: context.tr('circles.tab_previous'),
      },
      // How many wait for an answer, beside «الحالية».
      counts: needsReply == 0
          ? null
          : <NotificationsTab, int>{NotificationsTab.current: needsReply},
      selected: selected,
      onChanged: onChanged,
    );
  }
}
