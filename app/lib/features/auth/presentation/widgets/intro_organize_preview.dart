import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/auth/presentation/widgets/intro_next_dose_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:app/features/auth/presentation/widgets/intro_row_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_tile.dart';
import 'package:app/features/auth/presentation/widgets/intro_turned.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Page 1: the dark «الجرعة القادمة» card, and under it a reading and a
/// visit, each a little turned.
class IntroOrganizePreview extends StatelessWidget {
  const IntroOrganizePreview({super.key, required this.enter});

  final Animation<double> enter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: IntroRise(
            enter: enter,
            order: 0,
            child: const IntroNextDoseCard(),
          ),
        ),
        Positioned(
          top: 214,
          left: -6,
          right: 18,
          child: IntroRise(
            enter: enter,
            order: 1,
            child: IntroTurned(
              degrees: -2,
              child: IntroRowCard(
                tile: const IntroTile(
                  icon: AppIcons.drop,
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
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: 18,
          right: -6,
          child: IntroRise(
            enter: enter,
            order: 2,
            child: IntroTurned(
              degrees: 1.5,
              child: IntroRowCard(
                tile: const IntroTile(
                  icon: AppIcons.calendar,
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
            ),
          ),
        ),
      ],
    );
  }
}
