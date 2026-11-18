import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// How many invitations and requests wait for a reply, over their cards.
class NeedsReplyHeader extends StatelessWidget {
  const NeedsReplyHeader({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.inset,
        bottom: AppSpacing.labelGap,
      ),
      child: Text(
        context.tr('circles.needs_reply', args: <String>['$count']),
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: context.tokens.textSecondary),
      ),
    );
  }
}
