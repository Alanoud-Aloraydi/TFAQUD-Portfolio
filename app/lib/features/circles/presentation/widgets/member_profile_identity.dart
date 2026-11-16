import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_badges.dart';
import 'package:app/features/circles/presentation/widgets/member_patient_line.dart';
import 'package:flutter/material.dart';

/// Who a member is, read as one stop: their photo, their name, the line
/// that says they are the patient, and their badges.
class MemberProfileIdentity extends StatelessWidget {
  const MemberProfileIdentity({
    super.key,
    required this.member,
    required this.photoPath,
    required this.patientUsesApp,
  });

  /// Large enough to be the first thing on the card.
  static const double photoSize = 96;

  final CircleMember member;
  final String photoPath;
  final bool patientUsesApp;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Center(
            child: PersonPhoto(
              name: member.name,
              photoPath: photoPath,
              avatarCode: member.avatarCode,
              size: photoSize,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: text.titleLarge,
          ),
          if (member.isPatient) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            MemberPatientLine(usesApp: patientUsesApp),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: memberBadges(context, member),
          ),
        ],
      ),
    );
  }
}
