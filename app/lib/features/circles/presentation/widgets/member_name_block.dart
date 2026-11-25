import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The member's name with «أنت» for the viewer, and under the patient
/// «المريض، يستخدم التطبيق».
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
    return MergeSemantics(
      child: Column(
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
          // The patient is named as the patient whether or not they sign
          // in; the line only changes its ending.
          if (member.isPatient)
            Text(
              context.tr(
                patientUsesApp
                    ? 'circle_overview.patient_line'
                    : 'circle_overview.patient_line_no_app',
              ),
              style: text.bodySmall,
            ),
        ],
      ),
    );
  }
}

/// «أنت»: a small ink capsule after the viewer's name.
class YouPill extends StatelessWidget {
  const YouPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: const ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: StadiumBorder(),
      ),
      child: Text(
        context.tr('circle_overview.you'),
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: AppSemanticColors.surfaceContent),
      ),
    );
  }
}

/// Tells the leader how a change to a member went: [doneKey] in a toast,
/// or the error in a red one.
void showMemberActionResult(
  BuildContext context,
  String? errorKey,
  String doneKey,
) {
  if (!context.mounted) return;
  if (errorKey == null) {
    AppToast.show(context, doneKey);
    return;
  }
  AppToast.show(context, errorKey, kind: ToastKind.error);
}
