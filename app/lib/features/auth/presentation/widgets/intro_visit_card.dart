import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/auth/presentation/widgets/intro_row_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_tile.dart';
import 'package:app/features/auth/presentation/widgets/intro_turned.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The demo visit, a little turned.
class IntroVisitCard extends StatelessWidget {
  const IntroVisitCard({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroTurned(
      degrees: 1.5,
      child: IntroRowCard(
        tile: const IntroTile(
          icon: ScheduleIcons.calendar,
          background: AppSemanticColors.surfaceAttention,
          foreground: AppSemanticColors.statusWarning,
        ),
        title: context.tr('intro.demo.visit'),
        note: context.tr('intro.demo.visit_note'),
        trailing: StatusBadge(
          text: context.tr('intro.demo.visit_in'),
          tone: StatusTone.neutral,
        ),
      ),
    );
  }
}
