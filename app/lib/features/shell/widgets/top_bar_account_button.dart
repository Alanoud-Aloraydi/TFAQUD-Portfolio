import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/navigation/glass_icon_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/network/account_endpoints.dart';

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
