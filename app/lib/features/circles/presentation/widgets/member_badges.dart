import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// What a member is, as small badges: «مدير», «مشاهدة فقط» for a member
/// whose editing is paused, and «صاحب الملف» for the patient.
class MemberBadges extends StatelessWidget {
  const MemberBadges({super.key, required this.member});

  final CircleMember member;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (member.isManager)
          StatusPill(
            text: context.tr('circle_overview.manager'),
            background: AppSemanticColors.borderPlan,
            foreground: AppSemanticColors.textSupporting,
            icon: AppIcons.crown,
          ),
        if (member.isViewOnly)
          StatusPill(
            text: context.tr('circle_overview.view_only'),
            background: AppSemanticColors.borderPlan,
            foreground: AppSemanticColors.textSupporting,
            icon: AppIcons.lock,
          ),
        if (member.isPatient) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          StatusPill(
            text: context.tr('circle_overview.owner'),
            background: AppSemanticColors.selectedSurface,
            foreground: AppSemanticColors.statusSuccess,
            icon: AppIcons.user,
          ),
        ],
      ],
    );
  }
}
