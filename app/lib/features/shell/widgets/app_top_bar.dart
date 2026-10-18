import 'package:app/core/navigation/routers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Top bar of the shell: account button, circles area and notifications button.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key, this.hasUnreadNotifications = false});

  final bool hasUnreadNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: context.tr('topbar.account'),
        icon: const Icon(Icons.person_outline),
        onPressed: () => context.push(Routes.account),
      ),
      // The circles row is not implemented until circle data exists. The add-circle
      // button is disabled until its destination exists.
      title: Align(
        alignment: AlignmentDirectional.centerStart,
        child: IconButton(
          tooltip: context.tr('topbar.add_circle'),
          icon: const Icon(Icons.add_circle_outline),
          onPressed: null,
        ),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: context.tr('topbar.notifications'),
          icon: Badge(
            isLabelVisible: hasUnreadNotifications,
            smallSize: 8,
            child: const Icon(Icons.notifications_none),
          ),
          onPressed: () => context.push(Routes.notifications),
        ),
      ],
    );
  }
}
