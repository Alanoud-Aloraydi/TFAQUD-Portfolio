import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:flutter/material.dart';

/// An error under a form row, lined up with the value column: an icon and a
/// short message, so it is not color alone.
class InsetRowError extends StatelessWidget {
  const InsetRowError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg + AppSizes.formLabel + AppSpacing.md,
        end: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            AppIcons.warningCircle,
            size: AppSizes.iconSmall,
            color: tokens.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: tokens.errorText),
            ),
          ),
        ],
      ),
    );
  }
}
