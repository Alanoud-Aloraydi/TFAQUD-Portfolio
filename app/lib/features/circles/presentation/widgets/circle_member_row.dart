import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_photo_path.dart';
import 'package:app/features/circles/presentation/widgets/member_profile_sheet.dart';
import 'package:app/features/circles/presentation/widgets/member_row_content.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One member of the circle. Tapping the viewer's own row opens their
/// account; any other row opens that member's card, to call them.
class CircleMemberRow extends StatelessWidget {
  const CircleMemberRow({
    super.key,
    required this.member,
    required this.circleId,
    required this.patientUsesApp,
    required this.patientIsYou,
    required this.canManageMembers,
  });

  final CircleMember member;
  final String circleId;
  final bool patientUsesApp;
  final bool patientIsYou;
  final bool canManageMembers;

  @override
  Widget build(BuildContext context) {
    final String photoPath = memberPhotoPath(
      member,
      circleId: circleId,
      patientIsYou: patientIsYou,
    );
    return InkWell(
      onTap: () => _open(context, photoPath),
      child: MemberRowContent(
        member: member,
        photoPath: photoPath,
        patientUsesApp: patientUsesApp,
        canManageMembers: canManageMembers,
      ),
    );
  }

  void _open(BuildContext context, String photoPath) {
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
