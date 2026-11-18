import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/auth/presentation/widgets/intro_row_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_tile.dart';
import 'package:app/features/auth/presentation/widgets/intro_turned.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The demo reading, a little turned.
class IntroReadingCard extends StatelessWidget {
  const IntroReadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroTurned(
      degrees: -2,
      child: IntroRowCard(
        tile: const IntroTile(
          icon: CareIcons.drop,
          background: AppSemanticColors.selectedSurface,
          foreground: AppSemanticColors.statusSuccess,
        ),
        title: context.tr('intro.demo.reading'),
        note: context.tr('intro.demo.reading_note'),
        trailing: StatusBadge(
          text: context.tr('intro.demo.reading_value'),
          tone: StatusTone.success,
        ),
      ),
    );
  }
}
