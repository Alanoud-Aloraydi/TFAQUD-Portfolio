import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/widgets/glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Top bar of the shell: account button, circles area and notifications button.
/// The account and notifications buttons are round glass controls on the
/// canvas, with no bar or divider behind them (design system TopBar).
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      // No bar behind the controls: content scrolls under them, fading out
      // (a soft scroll edge effect) so the controls stay readable.
      backgroundColor: Colors.transparent,
      flexibleSpace: const IgnorePointer(child: _ScrollEdge()),
      toolbarHeight: kToolbarHeight + AppSpacing.sm,
      leadingWidth: AppSizes.glassButton + AppSpacing.lg,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: Center(
          child: GlassIconButton(
            tooltip: context.tr('topbar.account'),
            icon: displayName == null
                ? const Icon(Icons.person_outline)
                : Text(
                    displayName!.characters.first,
                    semanticsLabel: displayName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
            onPressed: () => context.push(Routes.account),
          ),
        ),
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
        GlassIconButton(
          // The tooltip is also what a screen reader says, so it carries the
          // count: the dot alone would be a colour and nothing else.
          tooltip: needsReply > 0
              ? context.tr('topbar.notifications_new', args: <String>['$needsReply'])
              : context.tr('topbar.notifications'),
          // The badge is an ink capsule with the count in white (14.99:1);
          // it never uses the error red.
          icon: needsReply > 0
              ? Badge(
                  label: Text('$needsReply'),
                  backgroundColor: AppColors.ink,
                  textColor: AppColors.surface,
                  child: const Icon(Icons.notifications_none),
                )
              : const Icon(Icons.notifications_none),
          onPressed: onNotifications,
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }
}

/// Soft scroll edge effect: the canvas fades in behind the top controls.
class _ScrollEdge extends StatelessWidget {
  const _ScrollEdge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.canvas.withValues(alpha: 0.96),
            AppColors.canvas.withValues(alpha: 0.75),
            AppColors.canvas.withValues(alpha: 0),
          ],
          stops: const <double>[0, 0.6, 1],
        ),
      ),
    );
  }
}
