import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/cubit/circle_overview_cubit.dart';
import 'package:app/features/circles/presentation/widgets/member_access_actions.dart';
import 'package:app/features/circles/presentation/widgets/member_access_buttons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the circle's leader («قائد الدائرة») decides about one member, in a
/// panel of its own under that member's row: a chip for each area they may
/// edit, then handing over the circle or taking the member out of it. The
/// panel keeps one member's controls from reading as the next member's.
/// Disabled while another change is on its way.
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
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppSemanticColors.background,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppSemanticColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            context.tr('circle_overview.allow_editing'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          _areas(context, accountId, enabled),
          const Divider(height: AppSpacing.lg),
          MemberAccessButtons(
            member: member,
            accountId: accountId,
            enabled: enabled,
            canHandOver: canHandOver,
          ),
        ],
      ),
    );
  }

  Widget _areas(BuildContext context, String? accountId, bool enabled) {
    final EditAccess access = member.editAccess;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: <Widget>[
        for (final String area in EditAccess.areas)
          FilterChip(
            label: Text(context.tr('circle_overview.area.$area')),
            selected: access.of(area),
            onSelected: enabled && accountId != null
                ? (bool allowed) => changeMemberAccess(
                    context,
                    accountId,
                    area: area,
                    allowed: allowed,
                  )
                : null,
          ),
      ],
    );
  }
}
