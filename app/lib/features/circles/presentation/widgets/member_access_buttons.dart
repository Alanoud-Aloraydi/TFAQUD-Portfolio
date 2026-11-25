import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/app_alert.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/confirm_hand_over.dart';
import 'package:app/features/circles/presentation/widgets/member_name_block.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            icon: const Icon(PeopleIcons.crown, size: AppSizes.iconSmall),
            label: Text(context.tr('circle_overview.hand_over')),
          ),
        TextButton.icon(
          onPressed: on ? () => confirmRemoveMember(context, member, id) : null,
          style: TextButton.styleFrom(
            foregroundColor: context.tokens.errorText,
            disabledForegroundColor: AppSemanticColors.borderControlBase,
          ),
          icon: const Icon(ActionIcons.trash, size: AppSizes.iconSmall),
          label: Text(context.tr('circle_overview.remove_member')),
        ),
      ],
    );
  }
}

/// Asks the leader to confirm, then removes the member from the circle.
Future<void> confirmRemoveMember(
  BuildContext context,
  CircleMember member,
  String accountId,
) async {
  final bool? confirmed = await showAppAlert<bool>(
    context,
    title: context.tr('circle_overview.remove_member_title'),
    message: context.tr(
      'circle_overview.remove_member_message',
      args: <String>[member.name],
    ),
    actions: <AppAlertAction<bool>>[
      AppAlertAction<bool>(label: context.tr('common.cancel'), value: false),
      AppAlertAction<bool>(
        label: context.tr('circle_overview.remove_member'),
        value: true,
        destructive: true,
      ),
    ],
  );
  if (confirmed != true || !context.mounted) return;
  final String? error = await context.read<CircleOverviewCubit>().removeMember(
    accountId,
  );
  if (!context.mounted) return;
  showMemberActionResult(context, error, 'toast.member_removed');
}
