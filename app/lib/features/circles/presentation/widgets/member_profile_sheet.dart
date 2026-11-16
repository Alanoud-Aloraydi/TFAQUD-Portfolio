import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/overlays/glass_sheet.dart';
import 'package:app/features/circles/domain/entities/circle_overview.dart';
import 'package:app/features/circles/presentation/widgets/member_phone_card.dart';
import 'package:app/features/circles/presentation/widgets/member_profile_actions.dart';
import 'package:app/features/circles/presentation/widgets/member_profile_identity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

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
