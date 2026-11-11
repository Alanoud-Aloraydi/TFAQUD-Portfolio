import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_access_controls.dart';
import 'package:app/features/circles/presentation/widgets/member_badges.dart';
import 'package:flutter/widgets.dart';

/// The end of a member row: the owner's access controls on every other
/// member, and the badges for everyone else.
class MemberTrailing extends StatelessWidget {
  const MemberTrailing({
    super.key,
    required this.member,
    required this.canManageMembers,
  });

  final CircleMember member;
  final bool canManageMembers;

  @override
  Widget build(BuildContext context) {
    if (canManageMembers && !member.isYou && !member.isPatient) {
      return MemberAccessControls(member: member);
    }
    return MemberBadges(member: member);
  }
}
