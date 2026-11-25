import 'dart:async';

import 'package:app/app/router/routers.dart';
import 'package:app/core/media/person_photo.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/utils/phone_call.dart';
import 'package:app/core/utils/saudi_mobile.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/feedback/app_toast.dart';
import 'package:app/core/widgets/overlays/glass_menu_route.dart';
import 'package:app/features/circles/domain/entities/circle_member.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_badges.dart';
import 'package:app/features/circles/presentation/widgets/member_name_block.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// The layout of a member row: portrait, name, and the member's badges at
/// the end of the row.
class MemberRowContent extends StatelessWidget {
  const MemberRowContent({
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
          MemberBadges(member: member),
        ],
      ),
    );
  }
}

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
  final String? phone = member.phoneNumber;
  return showGlassSheet<void>(
    context,
    title: context.tr('circle_overview.member_title'),
    builder: (BuildContext sheetContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MemberProfileIdentity(
          member: member,
          photoPath: photoPath,
          patientUsesApp: patientUsesApp,
        ),
        const SizedBox(height: AppSpacing.lg),
        MemberPhoneCard(phone: phone),
        if (phone != null) ...memberProfileActions(sheetContext, phone),
      ],
    ),
  );
}

/// «اتصال» and «نسخ الرقم» under a member's number, in the order a contact
/// card has them on iPhone.
List<Widget> memberProfileActions(BuildContext context, String phone) =>
    <Widget>[
      const SizedBox(height: AppSpacing.lg),
      PillButton(
        label: context.tr('circle_overview.member_call'),
        onPressed: () => unawaited(callNumber(phone)),
      ),
      const SizedBox(height: AppSpacing.xs),
      TextButton.icon(
        onPressed: () => _copy(context, phone),
        icon: const Icon(CupertinoIcons.doc_on_doc, size: AppSizes.iconSmall),
        label: Text(context.tr('circle_overview.member_copy')),
      ),
    ];

void _copy(BuildContext context, String phone) {
  unawaited(Clipboard.setData(ClipboardData(text: phone)));
  HapticFeedback.selectionClick();
  AppToast.show(context, 'circle_overview.member_copied');
}

/// A member's number, or the line that says a patient without an account
/// has none in the app.
class MemberPhoneCard extends StatelessWidget {
  const MemberPhoneCard({super.key, required this.phone});

  final String? phone;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? number = phone;
    return MergeSemantics(
      child: DecoratedBox(
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
              if (number != null)
                // A number reads left to right inside Arabic text.
                Text(
                  SaudiMobile.display(number),
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
    );
  }
}

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

/// The line under a patient's name on their card, which says whether they
/// use the app themselves.
class MemberPatientLine extends StatelessWidget {
  const MemberPatientLine({super.key, required this.usesApp});

  final bool usesApp;

  @override
  Widget build(BuildContext context) => Text(
    context.tr(
      usesApp
          ? 'circle_overview.patient_line'
          : 'circle_overview.patient_line_no_app',
    ),
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: context.tokens.textSecondary),
  );
}
