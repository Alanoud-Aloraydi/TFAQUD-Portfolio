import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_access_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The two things the leader can do to a member, as labelled buttons:
/// handing over the circle, and taking the member out of it. Both say what
/// they do, so the red one is never a bare icon.
class MemberAccessButtons extends StatelessWidget {
  const MemberAccessButtons({
    super.key,
    required this.member,
    required this.accountId,
    required this.enabled,
    required this.canHandOver,
  });

  final CircleMember member;
  final String? accountId;
  final bool enabled;
  final bool canHandOver;

  @override
  Widget build(BuildContext context) {
    final String? id = accountId;
    final bool on = enabled && id != null;
    // Both labels on one line on a wide phone; on a narrow one they wrap
    // instead of running off the edge.
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        if (canHandOver)
          TextButton.icon(
            onPressed: on ? () => confirmHandOver(context, member, id) : null,
            icon: const Icon(AppIcons.crown, size: AppSizes.iconSmall),
            label: Text(context.tr('circle_overview.hand_over')),
          ),
        TextButton.icon(
          onPressed: on ? () => confirmRemoveMember(context, member, id) : null,
          style: TextButton.styleFrom(
            foregroundColor: context.tokens.errorText,
            disabledForegroundColor: AppSemanticColors.borderControlBase,
          ),
          icon: const Icon(AppIcons.trash, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.remove_member')),
        ),
      ],
    );
  }
}
