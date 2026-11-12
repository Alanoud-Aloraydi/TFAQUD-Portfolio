import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Shown in a tab of the bell with nothing in it: the bell and the words of
/// [messageKey].
class NotificationsEmpty extends StatelessWidget {
  const NotificationsEmpty({super.key, required this.messageKey});

  final String messageKey;

  static const double _topGap = 96;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: _topGap),
        Icon(
          AppIcons.bell,
          size: AppSizes.iconHero,
          color: context.tokens.textSecondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.tr(messageKey),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: context.tokens.textSecondary),
        ),
      ],
    );
  }
}
