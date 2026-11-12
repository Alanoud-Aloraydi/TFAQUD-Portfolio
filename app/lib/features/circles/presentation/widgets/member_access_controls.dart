import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/member_access_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the circle's leader («قائد الدائرة») decides about one member,
/// under the member's row: a chip for each area they may edit (the
/// medicines, the measurements, the appointments), removing them from the
/// circle, and handing them the leadership when [canHandOver]. Disabled
/// while another change is on its way.
class MemberAccessControls extends StatelessWidget {
  const MemberAccessControls({
    super.key,
    required this.member,
    required this.canHandOver,
  });

  final CircleMember member;
  final bool canHandOver;

  @override
  Widget build(BuildContext context) {
    final bool acting = context.select(
      (CircleOverviewCubit cubit) => cubit.state.acting,
    );
    final String? accountId = member.accountId;
    final bool enabled = !acting && accountId != null;
    final EditAccess access = member.editAccess;
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.tr('circle_overview.allow_editing'),
          style: text.labelSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            for (final String area in EditAccess.areas)
              FilterChip(
                label: Text(context.tr('circle_overview.area.$area')),
                selected: access.of(area),
                onSelected: enabled
                    ? (bool allowed) => changeMemberAccess(
                        context,
                        accountId,
                        area: area,
                        allowed: allowed,
                      )
                    : null,
              ),
          ],
        ),
        Row(
          children: <Widget>[
            if (canHandOver)
              TextButton.icon(
                onPressed: enabled
                    ? () => confirmHandOver(context, member, accountId)
                    : null,
                icon: const Icon(AppIcons.crown, size: AppSizes.iconSmall),
                label: Text(context.tr('circle_overview.hand_over')),
              ),
            const Spacer(),
            IconButton(
              tooltip: context.tr('circle_overview.remove_member'),
              onPressed: enabled
                  ? () => confirmRemoveMember(context, member, accountId)
                  : null,
              icon: const Icon(AppIcons.trash),
              color: context.tokens.errorText,
              disabledColor: AppSemanticColors.borderControlBase,
            ),
          ],
        ),
      ],
    );
  }
}
