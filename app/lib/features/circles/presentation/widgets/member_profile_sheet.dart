import 'dart:async';

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// A member's card, from the circle's members list: their photo and name,
/// their place in the circle, and their number with «اتصال» and «نسخ
/// الرقم» — the same order as a contact card on iPhone. A patient without
/// an account has no number in the app, and the card says so.
Future<void> showMemberProfileSheet(
  BuildContext context, {
  required CircleMember member,
  required String photoPath,
  required bool patientUsesApp,
}) {
  return showGlassSheet<void>(
    context,
    title: context.tr('circle_overview.member_title'),
    builder: (BuildContext sheetContext) => _MemberProfile(
      member: member,
      photoPath: photoPath,
      patientUsesApp: patientUsesApp,
    ),
  );
}

class _MemberProfile extends StatelessWidget {
  const _MemberProfile({
    required this.member,
    required this.photoPath,
    required this.patientUsesApp,
  });

  final CircleMember member;
  final String photoPath;
  final bool patientUsesApp;

  static const double _photo = 96;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? phone = member.phoneNumber;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: PersonPhoto(
            name: member.name,
            photoPath: photoPath,
            avatarCode: member.avatarCode,
            size: _photo,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(member.name, textAlign: TextAlign.center, style: text.titleLarge),
        if (member.isPatient && patientUsesApp) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Text(
            context.tr('circle_overview.patient_line'),
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(
              color: context.tokens.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: <Widget>[
            if (member.isManager)
              StatusPill(
                text: context.tr('circle_overview.manager'),
                background: AppSemanticColors.borderPlan,
                foreground: AppSemanticColors.textSupporting,
                icon: AppIcons.crown,
              ),
            if (member.isPatient)
              StatusPill(
                text: context.tr('circle_overview.owner'),
                background: AppSemanticColors.selectedSurface,
                foreground: AppSemanticColors.statusSuccess,
                icon: AppIcons.user,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        DecoratedBox(
          decoration: ShapeDecoration(
            color: AppSemanticColors.surfaceContent,
            shape: AppRadius.shape(AppRadius.m, side: AppSurfaces.edge),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  context.tr('circle_overview.member_phone'),
                  style: text.bodySmall?.copyWith(
                    color: context.tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (phone != null)
                  // A number reads left to right inside Arabic text.
                  Text(
                    SaudiMobile.display(phone),
                    textDirection: TextDirection.ltr,
                    style: text.titleMedium,
                  )
                else
                  Text(
                    context.tr('circle_overview.member_no_phone'),
                    style: text.bodyMedium,
                  ),
              ],
            ),
          ),
        ),
        if (phone != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          PillButton(
            label: context.tr('circle_overview.member_call'),
            onPressed: () => unawaited(_call(phone)),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () => _copy(context, phone),
            icon: const Icon(
              CupertinoIcons.doc_on_doc,
              size: AppSizes.iconSmall,
            ),
            label: Text(context.tr('circle_overview.member_copy')),
          ),
        ],
      ],
    );
  }

  Future<void> _call(String phone) =>
      launchUrl(Uri(scheme: 'tel', path: phone.replaceAll(' ', '')));

  void _copy(BuildContext context, String phone) {
    unawaited(Clipboard.setData(ClipboardData(text: phone)));
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('circle_overview.member_copied'))),
    );
  }
}
