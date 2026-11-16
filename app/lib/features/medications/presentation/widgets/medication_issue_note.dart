import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a field of the medicine's form refused, under the group it belongs
/// to: the warning sign and [messageKey] in the error colour.
class MedicationIssueNote extends StatelessWidget {
  const MedicationIssueNote({super.key, required this.messageKey});

  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.lg,
        end: AppSpacing.lg,
        top: AppSpacing.sm,
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
              context.tr(messageKey),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: tokens.errorText),
            ),
          ),
        ],
      ),
    );
  }
}
