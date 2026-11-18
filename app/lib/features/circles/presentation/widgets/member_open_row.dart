import 'package:app/core/navigation/routers.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/presentation/widgets/member_profile_sheet.dart';
import 'package:app/features/circles/presentation/widgets/member_row_content.dart';
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
