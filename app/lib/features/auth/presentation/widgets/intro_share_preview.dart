import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/auth/presentation/widgets/intro_card_header.dart';
import 'package:app/features/auth/presentation/widgets/intro_done.dart';
import 'package:app/features/auth/presentation/widgets/intro_first_letter.dart';
import 'package:app/features/auth/presentation/widgets/intro_floating_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_initial.dart';
import 'package:app/features/auth/presentation/widgets/intro_line.dart';
import 'package:app/features/auth/presentation/widgets/intro_person.dart';
import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Page 2: the members of the circle, and a dark note over them.
class IntroSharePreview extends StatelessWidget {
  const IntroSharePreview({super.key, required this.enter});

  final Animation<double> enter;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget admin = StatusBadge(
      text: context.tr('intro.demo.admin'),
      tone: StatusTone.neutral,
    );
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
            child: IntroFloatingCard(
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
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: 8,
          right: 8,
          child: IntroRise(
            enter: enter,
            order: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              decoration: ShapeDecoration(
                color: AppSemanticColors.textPrimary,
                shape: AppRadius.shape(AppRadius.m),
                shadows: AppSurfaces.floatShadow,
              ),
              child: Row(
                children: <Widget>[
                  IntroInitial(
                    letter: firstLetter(context.tr('intro.demo.khalid')),
                    color: AppSemanticColors.surfaceAttention,
                    size: 30,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: <InlineSpan>[
                          TextSpan(
                            text: context.tr('intro.demo.khalid'),
                            style: const TextStyle(
                              fontWeight: AppTextTheme.bold,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: context.tr('intro.demo.khalid_logged'),
                          ),
                        ],
                      ),
                      style: text.bodyMedium?.copyWith(
                        color: AppSemanticColors.surfaceContent,
                      ),
                    ),
                  ),
                  const IntroDone(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
