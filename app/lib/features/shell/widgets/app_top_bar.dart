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
  });

  final String? displayName;
  final Widget? circles;

  /// Called by the "+" button next to the circles. Null turns the button off.
  final VoidCallback? onAddCircle;

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
          tooltip: context.tr('topbar.notifications'),
          icon: const Icon(Icons.notifications_none),
          onPressed: null,
        ),
      ],
    );
  }
}
