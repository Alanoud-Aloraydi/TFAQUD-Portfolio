import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// «متحقق» when the contact's number uses تفقُد, «غير متحقق» when not.
/// Words and an icon, never colour alone.
class ContactVerifiedBadge extends StatelessWidget {
  const ContactVerifiedBadge({super.key, required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) => StatusBadge(
    text: context.tr(
      verified ? 'circles.contact_verified' : 'circles.contact_unverified',
    ),
    tone: verified ? StatusTone.success : StatusTone.muted,
    icon: verified ? AppIcons.checkCircle : AppIcons.warningCircle,
  );
}
