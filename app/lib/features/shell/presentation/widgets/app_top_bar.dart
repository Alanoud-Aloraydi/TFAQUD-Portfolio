import 'package:app/app/router/routers.dart';
import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/network/account_endpoints.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
import 'package:app/core/widgets/navigation/glass_icon_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

/// Soft scroll edge effect: the canvas fades in behind the top controls.
class TopBarScrollEdge extends StatelessWidget {
  const TopBarScrollEdge({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: AppGlass.scrollEdge),
    );
  }
}

/// The account button at the start of the top bar: the person's photo, or a
/// user icon before the name is known. [onPhotoSaved] runs when the account
/// page closes.
class TopBarAccountButton extends StatelessWidget {
  const TopBarAccountButton({
    super.key,
    this.displayName,
    this.avatarCode,
    this.onPhotoSaved,
  });

  final String? displayName;
  final String? avatarCode;
  final VoidCallback? onPhotoSaved;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      size: AppSizes.avatarPortrait,
      tooltip: context.tr('topbar.account'),
      icon: displayName == null
          ? const Icon(PeopleIcons.user)
          : PersonPhoto(
              name: displayName!,
              photoPath: AccountEndpoints.accountPhoto,
              avatarCode: avatarCode,
              size: AppSizes.avatarPortrait,
            ),
      onPressed: () async {
        await context.push<void>(Routes.account);
        if (context.mounted) onPhotoSaved?.call();
      },
    );
  }
}

/// The bell at the end of the top bar. It shows the count of waiting
/// requests and invitations as a badge. A null [onPressed] turns it off.
class TopBarNotificationsButton extends StatelessWidget {
  const TopBarNotificationsButton({
    super.key,
    required this.needsReply,
    this.onPressed,
  });

  final int needsReply;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassIconButton(
      // The tooltip is also what a screen reader says, so it carries the
      // count: the dot alone would be a colour and nothing else.
      tooltip: needsReply > 0
          ? context.tr(
              'topbar.notifications_new',
              args: <String>['$needsReply'],
            )
          : context.tr('topbar.notifications'),
      // The badge is an ink capsule with the count in white (14.99:1);
      // it never uses the error red.
      icon: needsReply > 0
          ? Badge(
              label: Text('$needsReply'),
              backgroundColor: AppSemanticColors.textPrimary,
              textColor: AppSemanticColors.surfaceContent,
              child: const Icon(NoticeIcons.bell),
            )
          : const Icon(NoticeIcons.bell),
      onPressed: onPressed,
    );
  }
}
