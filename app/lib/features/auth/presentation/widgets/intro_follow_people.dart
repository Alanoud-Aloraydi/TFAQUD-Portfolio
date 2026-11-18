import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/auth/presentation/widgets/intro_card_header.dart';
import 'package:app/features/auth/presentation/widgets/intro_floating_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_follow_add.dart';
import 'package:app/features/auth/presentation/widgets/intro_follow_selected.dart';
import 'package:app/features/auth/presentation/widgets/intro_line.dart';
import 'package:app/features/auth/presentation/widgets/intro_person.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The list the person switcher opens.
class IntroFollowPeople extends StatelessWidget {
  const IntroFollowPeople({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroFloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          IntroCardHeader(title: context.tr('intro.demo.who')),
          const IntroFollowSelected(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: IntroPerson(
              initial: context.tr('intro.demo.uncle_initial'),
              color: AppSemanticColors.selectedSurface,
              size: 44,
              name: context.tr('intro.demo.uncle'),
              note: context.tr('intro.demo.uncle_note'),
            ),
          ),
          const IntroLine(),
          const IntroFollowAdd(),
        ],
      ),
    );
  }
}
