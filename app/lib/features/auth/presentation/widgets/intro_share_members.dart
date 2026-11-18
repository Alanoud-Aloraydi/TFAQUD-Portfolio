import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/auth/presentation/widgets/intro_card_header.dart';
import 'package:app/features/auth/presentation/widgets/intro_first_letter.dart';
import 'package:app/features/auth/presentation/widgets/intro_floating_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_line.dart';
import 'package:app/features/auth/presentation/widgets/intro_person.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The members of the circle, in a floating card.
class IntroShareMembers extends StatelessWidget {
  const IntroShareMembers({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget admin = StatusBadge(
      text: context.tr('intro.demo.admin'),
      tone: StatusTone.neutral,
    );
    return IntroFloatingCard(
      child: Column(
        children: <Widget>[
          IntroCardHeader(
            title: context.tr('intro.demo.circle'),
            note: context.tr('intro.demo.members'),
          ),
          IntroPerson(
            initial: firstLetter(context.tr('intro.demo.reem')),
            color: AppSemanticColors.selectedSurface,
            name: context.tr('intro.demo.reem'),
            note: context.tr('intro.demo.you'),
            trailing: admin,
          ),
          const IntroLine(),
          IntroPerson(
            initial: firstLetter(context.tr('intro.demo.khalid')),
            color: AppSemanticColors.surfaceAttention,
            name: context.tr('intro.demo.khalid'),
            note: context.tr('intro.demo.khalid_note'),
            trailing: admin,
          ),
          const IntroLine(),
          IntroPerson(
            initial: firstLetter(context.tr('intro.demo.nouf')),
            color: AppSemanticColors.segmentTrack,
            name: context.tr('intro.demo.nouf'),
            note: context.tr('intro.demo.nouf_note'),
          ),
        ],
      ),
    );
  }
}
