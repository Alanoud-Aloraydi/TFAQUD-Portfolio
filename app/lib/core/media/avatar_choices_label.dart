import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «اختر شخصية» and a line to the far edge, above the avatars.
class AvatarChoicesLabel extends StatelessWidget {
  const AvatarChoicesLabel({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          context.tr('photos.choose_character'),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(child: Divider()),
      ],
    );
  }
}
