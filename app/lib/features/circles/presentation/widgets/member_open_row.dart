import 'package:app/app/router/routers.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_badges.dart';
import 'package:app/features/circles/presentation/widgets/member_name_block.dart';
import 'package:app/features/circles/presentation/widgets/member_profile_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The row of one member as a button. Tapping the viewer's own row opens
/// their account; any other row opens that member's card, to call them.
class MemberOpenRow extends StatelessWidget {
  const MemberOpenRow({
    super.key,
    required this.member,
    required this.photoPath,
    required this.patientUsesApp,
  });

  final CircleMember member;
  final String photoPath;
  final bool patientUsesApp;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: () => _open(context),
          child: MemberRowContent(
            member: member,
            photoPath: photoPath,
            patientUsesApp: patientUsesApp,
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    if (member.isYou) {
      context.push(Routes.account);
      return;
    }
    showMemberProfileSheet(
      context,
      member: member,
      photoPath: photoPath,
      patientUsesApp: patientUsesApp,
    );
  }
}

/// The layout of a member row: portrait, name, and the member's badges at
/// the end of the row.
class MemberRowContent extends StatelessWidget {
  const MemberRowContent({
    super.key,
    required this.member,
    required this.photoPath,
    required this.patientUsesApp,
  });

  final CircleMember member;
  final String photoPath;
  final bool patientUsesApp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          PersonPhoto(
            name: member.name,
            photoPath: photoPath,
            avatarCode: member.avatarCode,
            size: AppSizes.avatarPortrait,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: MemberNameBlock(
              member: member,
              patientUsesApp: patientUsesApp,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          MemberBadges(member: member),
        ],
      ),
    );
  }
}
