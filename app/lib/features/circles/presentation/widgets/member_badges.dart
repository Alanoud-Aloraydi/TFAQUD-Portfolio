import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a member is in the circle, as badges: «قائد الدائرة» for its one
/// leader, «صاحب الملف» for the patient, «مشاهدة فقط» for a member the
/// leader lets edit nothing, and «تعديل محدود» for one who edits some areas
/// only. A member who edits everything has no badge.
List<Widget> memberBadges(BuildContext context, CircleMember member) {
  final EditAccess access = member.editAccess;
  final bool limited =
      !member.isLeader &&
      member.holdsMembership &&
      access.any &&
      !EditAccess.areas.every(access.of);
  return <Widget>[
    if (member.isLeader)
      StatusBadge(
        text: context.tr('circle_overview.leader'),
        tone: StatusTone.attention,
        icon: AppIcons.crown,
      ),
    if (member.isPatient)
      StatusBadge(
        text: context.tr('circle_overview.owner'),
        tone: StatusTone.success,
        icon: AppIcons.user,
      ),
    if (member.isViewOnly)
      StatusBadge(
        text: context.tr('circle_overview.view_only'),
        tone: StatusTone.muted,
        icon: AppIcons.lock,
      ),
    if (limited)
      StatusBadge(
        text: context.tr('circle_overview.limited_editing'),
        tone: StatusTone.neutral,
        icon: AppIcons.pencil,
      ),
  ];
}

/// The badges of a member at the end of their row, one under the other.
class MemberBadges extends StatelessWidget {
  const MemberBadges({super.key, required this.member});

  final CircleMember member;

  @override
  Widget build(BuildContext context) {
    final List<Widget> badges = memberBadges(context, member);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (int i = 0; i < badges.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          badges[i],
        ],
      ],
    );
  }
}
