import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_name_block.dart';
import 'package:app/features/circles/presentation/widgets/member_trailing.dart';
import 'package:flutter/material.dart';

/// The layout of a member row: portrait, name, and the end of the row.
class MemberRowContent extends StatelessWidget {
  const MemberRowContent({
    super.key,
    required this.member,
    required this.photoPath,
    required this.patientUsesApp,
    required this.canManageMembers,
  });

  final CircleMember member;
  final String photoPath;
  final bool patientUsesApp;
  final bool canManageMembers;

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
          MemberTrailing(member: member, canManageMembers: canManageMembers),
        ],
      ),
    );
  }
}
