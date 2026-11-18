import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/shell/widgets/top_bar_account_button.dart';
import 'package:app/features/shell/widgets/top_bar_notifications_button.dart';
import 'package:app/features/shell/widgets/top_bar_scroll_edge.dart';
import 'package:flutter/material.dart';

/// Top bar of the shell (design system TopBar): the account button at the
/// start, the circle switcher in the middle and the notifications button at
/// the end, all floating glass on the canvas with no bar or divider behind
/// them. The tab's large title sits under them and scrolls with the content.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.displayName,
    this.avatarCode,
    this.onPhotoSaved,
    this.circles,
    this.needsReply = 0,
    this.onNotifications,
  });

  final String? displayName;
  final String? avatarCode;
  final VoidCallback? onPhotoSaved;

  /// The circle switcher, centered between the two buttons.
  final Widget? circles;

  /// How many requests and invitations wait for an answer. The bell shows a dot
  /// when it is above zero.
  final int needsReply;

  /// Called by the bell. Null turns the button off.
  final VoidCallback? onNotifications;

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + AppSpacing.sm);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      // No bar behind the controls: content scrolls under them, fading out
      // (a soft scroll edge effect) so the controls stay readable.
      backgroundColor: AppSemanticColors.transparent,
      flexibleSpace: const IgnorePointer(child: TopBarScrollEdge()),
      toolbarHeight: kToolbarHeight + AppSpacing.sm,
      leadingWidth: AppSizes.avatarPortrait + AppSpacing.lg,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpacing.lg),
        child: Center(
          child: TopBarAccountButton(
            displayName: displayName,
            avatarCode: avatarCode,
            onPhotoSaved: onPhotoSaved,
          ),
        ),
      ),
      centerTitle: true,
      titleSpacing: AppSpacing.sm,
      title: circles,
      actions: <Widget>[
        TopBarNotificationsButton(
          needsReply: needsReply,
          onPressed: onNotifications,
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }
}
