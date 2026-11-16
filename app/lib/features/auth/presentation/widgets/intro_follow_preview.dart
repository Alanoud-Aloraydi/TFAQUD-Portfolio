import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/features/auth/presentation/widgets/intro_card_header.dart';
import 'package:app/features/auth/presentation/widgets/intro_floating_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_initial.dart';
import 'package:app/features/auth/presentation/widgets/intro_line.dart';
import 'package:app/features/auth/presentation/widgets/intro_person.dart';
import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Page 3: the person switcher of the top bar, and the list it opens.
class IntroFollowPreview extends StatelessWidget {
  const IntroFollowPreview({super.key, required this.enter});

  final Animation<double> enter;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String mother = context.tr('intro.demo.mother');
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: 8,
          left: 0,
          right: 0,
          child: IntroRise(
            enter: enter,
            order: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.tight,
                  AppSpacing.tight,
                  AppSpacing.md,
                  AppSpacing.tight,
                ),
                decoration: ShapeDecoration(
                  color: AppSemanticColors.surfaceContent.withValues(
                    alpha: 0.8,
                  ),
                  shape: const StadiumBorder(
                    side: BorderSide(color: AppSemanticColors.surfaceContent),
                  ),
                  shadows: AppSurfaces.floatShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IntroInitial(
                      letter: context.tr('intro.demo.mother_initial'),
                      color: AppSemanticColors.surfaceAttention,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(child: Text(mother, style: text.titleSmall)),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      AppIcons.caretDown,
                      size: AppSizes.iconSmall,
                      color: AppSemanticColors.textSupporting,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 74,
          left: 0,
          right: 0,
          child: IntroRise(
            enter: enter,
            order: 1,
            child: IntroFloatingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  IntroCardHeader(title: context.tr('intro.demo.who')),
                  // The person on show, picked.
                  DecoratedBox(
                    decoration: ShapeDecoration(
                      color: AppSemanticColors.selectedSurface,
                      shape: AppRadius.shape(AppRadius.m),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: IntroPerson(
                        initial: context.tr('intro.demo.mother_initial'),
                        color: AppSemanticColors.surfaceAttention,
                        size: 44,
                        name: mother,
                        note: context.tr('intro.demo.mother_note'),
                        trailing: const Icon(
                          AppIcons.checkCircle,
                          size: AppSizes.icon,
                          color: AppSemanticColors.statusSuccess,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: IntroPerson(
                      initial: context.tr('intro.demo.uncle_initial'),
                      color: AppSemanticColors.selectedSurface,
                      size: 44,
                      name: context.tr('intro.demo.uncle'),
                      note: context.tr('intro.demo.uncle_note'),
                    ),
                  ),
                  const IntroLine(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const ShapeDecoration(
                            color: AppSemanticColors.surfaceContent,
                            shape: CircleBorder(
                              side: BorderSide(
                                color: AppSemanticColors.borderControlBase,
                                width: AppSizes.borderEmphasis,
                              ),
                            ),
                          ),
                          child: const Icon(
                            AppIcons.plus,
                            size: AppSizes.iconSmall,
                            color: AppSemanticColors.textSupporting,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            context.tr('intro.demo.add_person'),
                            style: text.titleSmall?.copyWith(
                              color: AppSemanticColors.textSupporting,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
