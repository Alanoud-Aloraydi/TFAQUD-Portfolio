import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/you_pill.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The member's name with «أنت» for the viewer, and under the patient
/// «المريض · يستخدم التطبيق».
class MemberNameBlock extends StatelessWidget {
  const MemberNameBlock({
    super.key,
    required this.member,
    required this.patientUsesApp,
  });

  final CircleMember member;
  final bool patientUsesApp;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            Text(member.name, style: text.titleSmall),
            if (member.isYou) const YouPill(),
          ],
        ),
        if (member.isPatient && patientUsesApp)
          Text(
            context.tr('circle_overview.patient_line'),
            style: text.bodySmall,
          ),
      ],
    );
  }
}
