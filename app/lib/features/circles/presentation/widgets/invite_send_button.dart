import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «إرسال الدعوة» in ink with the paper plane in leaf. Null [onPressed]
/// while the invitation is on its way.
class InviteSendButton extends StatelessWidget {
  const InviteSendButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppSemanticColors.textPrimary,
        foregroundColor: AppSemanticColors.surfaceContent,
        iconColor: AppSemanticColors.accentLeaf,
      ),
      icon: const Icon(PeopleIcons.paperPlane, size: AppSizes.iconSmall),
      label: Text(context.tr('circle_overview.send_invite')),
    );
  }
}
