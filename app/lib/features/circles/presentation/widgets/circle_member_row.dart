import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_access_controls.dart';
import 'package:app/features/circles/presentation/widgets/member_photo_path.dart';
import 'package:app/features/circles/presentation/widgets/member_open_row.dart';
import 'package:flutter/material.dart';

/// One member of the circle. Tapping the viewer's own row opens their
/// account; any other row opens that member's card, to call them. The
/// circle's leader ([canManageMembers]) has, under every other member, what
/// they decide about them ([MemberAccessControls]).
class CircleMemberRow extends StatelessWidget {
  const CircleMemberRow({
    super.key,
    required this.member,
    required this.circleId,
    required this.patientUsesApp,
    required this.patientIsYou,
    required this.canManageMembers,
    this.canHandOver = false,
  });

  final CircleMember member;
  final String circleId;
  final bool patientUsesApp;
  final bool patientIsYou;
  final bool canManageMembers;

  /// Whether the leader may hand the leadership to another member.
  final bool canHandOver;

  @override
  Widget build(BuildContext context) {
    final String photoPath = memberPhotoPath(
      member,
      circleId: circleId,
      patientIsYou: patientIsYou,
    );
    final Widget row = MemberOpenRow(
      member: member,
      photoPath: photoPath,
      patientUsesApp: patientUsesApp,
    );
    // The leader decides about the others who hold a membership, not about
    // themself or a patient who only reads their own day.
    if (!canManageMembers || member.isYou || !member.holdsMembership) {
      return row;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        row,
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MemberAccessControls(member: member, canHandOver: canHandOver),
        ),
      ],
    );
  }
}
