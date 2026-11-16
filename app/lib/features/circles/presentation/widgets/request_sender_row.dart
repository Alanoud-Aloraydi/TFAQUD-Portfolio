import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The avatar with the sender's first letter, their name and a short line
/// saying what they asked, at the top of the request card.
Widget requestSenderRow(BuildContext context, String name) {
  final TextTheme text = Theme.of(context).textTheme;
  return Row(
    children: <Widget>[
      Container(
        width: AppSizes.avatarLarge,
        height: AppSizes.avatarLarge,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppSemanticColors.selectedSurface,
          shape: BoxShape.circle,
        ),
        child: Text(
          name.isEmpty ? '؟' : name.characters.first,
          style: text.titleLarge?.copyWith(
            color: AppSemanticColors.textPrimary,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(header: true, child: Text(name, style: text.titleMedium)),
            Text(
              context.tr('circles.reply_subtitle'),
              style: text.bodyMedium?.copyWith(
                color: context.tokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
