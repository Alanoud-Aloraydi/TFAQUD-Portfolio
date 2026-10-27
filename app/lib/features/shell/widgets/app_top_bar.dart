import 'package:app/core/navigation/routers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Top bar of the shell: account button, circles area and notifications button.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.displayName,
    this.circles,
    this.onAddCircle,
    this.needsReply = 0,
    this.onNotifications,
  });

  final String? displayName;
  final Widget? circles;

  /// Called by the "+" button next to the circles. Null turns the button off.
  final VoidCallback? onAddCircle;

  /// How many requests and invitations wait for an answer. The bell shows a dot
  /// when it is above zero.
  final int needsReply;

  /// Called by the bell. Null turns the button off.
  final VoidCallback? onNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        tooltip: context.tr('topbar.account'),
        icon: displayName == null
            ? const Icon(Icons.person_outline)
            : Text(displayName!.characters.first, semanticsLabel: displayName),
        onPressed: () => context.push(Routes.account),
      ),
      title: Row(
        children: [
          IconButton(
            tooltip: context.tr('topbar.add_circle'),
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onAddCircle,
          ),
          Expanded(child: circles ?? const SizedBox.shrink()),
        ],
      ),
      actions: <Widget>[
        IconButton(
          // The tooltip is also what a screen reader says, so it carries the
          // count: the dot alone would be a colour and nothing else.
          tooltip: needsReply > 0
              ? context.tr('topbar.notifications_new', args: <String>['$needsReply'])
              : context.tr('topbar.notifications'),
          icon: needsReply > 0
              ? const Badge(
                  smallSize: 8,
                  child: Icon(Icons.notifications_none),
                )
              : const Icon(Icons.notifications_none),
          onPressed: onNotifications,
        ),
      ],
    );
  }
}
