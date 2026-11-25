import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/edit_access.dart';
import 'package:app/features/circles/presentation/widgets/member_open_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Page 2: the members of a circle as «الدائرة» lists them: the patient,
/// you as its leader, and a member who edits the medicines only.
class IntroMembersPicture extends StatelessWidget {
  const IntroMembersPicture({super.key});

  @override
  Widget build(BuildContext context) {
    String name(String key) => context.tr('intro.demo.$key');
    final List<CircleMember> members = <CircleMember>[
      CircleMember(
        name: name('khalid'),
        isYou: false,
        isPatient: true,
        avatarCode: 'gh_3',
      ),
      CircleMember(
        name: name('leen'),
        isYou: true,
        isLeader: true,
        avatarCode: 'w1_1',
      ),
      CircleMember(
        name: name('alanoud'),
        isYou: false,
        avatarCode: 'w7_1',
        access: const EditAccess(
          medications: true,
          measurements: false,
          appointments: false,
        ),
      ),
    ];
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(AppRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          children: <Widget>[
            for (final CircleMember member in members) ...<Widget>[
              if (member != members.first)
                const Divider(
                  height: AppSizes.divider,
                  color: AppSemanticColors.borderPlan,
                ),
              MemberRowContent(
                member: member,
                photoPath: '',
                patientUsesApp: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
