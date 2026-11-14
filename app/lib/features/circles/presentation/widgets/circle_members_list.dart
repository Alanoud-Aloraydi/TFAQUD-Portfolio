import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/circle_invitation_row.dart';
import 'package:app/features/circles/presentation/widgets/circle_member_row.dart';
import 'package:flutter/material.dart';

/// The members, then the pending invitations, in one slate group with
/// lines between the rows.
class CircleMembersList extends StatelessWidget {
  const CircleMembersList({
    super.key,
    required this.overview,
    required this.circleId,
  });

  final CircleOverview overview;
  final String circleId;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[
      for (final CircleMember member in overview.members)
        CircleMemberRow(
          member: member,
          circleId: circleId,
          patientUsesApp: overview.patientUsesApp,
          patientIsYou: overview.patientIsYou,
          canManageMembers: overview.canManageMembers,
        ),
      for (final CirclePendingInvitation invitation
          in overview.pendingInvitations)
        CircleInvitationRow(
          invitation: invitation,
          canManage: overview.canManage,
        ),
    ];
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m, side: AppSurfaces.edge),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            for (int i = 0; i < rows.length; i++) ...<Widget>[
              if (i > 0)
                const Divider(
                  height: AppSizes.divider,
                  color: AppSemanticColors.borderPlan,
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}
