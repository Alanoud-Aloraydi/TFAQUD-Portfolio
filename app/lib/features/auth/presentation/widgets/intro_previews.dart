import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/status/status_badge.dart';
import 'package:app/features/auth/presentation/widgets/intro_card_header.dart';
import 'package:app/features/auth/presentation/widgets/intro_done.dart';
import 'package:app/features/auth/presentation/widgets/intro_first_letter.dart';
import 'package:app/features/auth/presentation/widgets/intro_floating_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_initial.dart';
import 'package:app/features/auth/presentation/widgets/intro_line.dart';
import 'package:app/features/auth/presentation/widgets/intro_next_dose_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_person.dart';
import 'package:app/features/auth/presentation/widgets/intro_rise.dart';
import 'package:app/features/auth/presentation/widgets/intro_row_card.dart';
import 'package:app/features/auth/presentation/widgets/intro_tile.dart';
import 'package:app/features/auth/presentation/widgets/intro_turned.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The picture of a welcome page: real parts of the app drawn with example
/// data, so the person knows the app before they open it.
///
/// 1. The next dose, a reading and a visit, as on «اليوم».
/// 2. The circle's members, and a note that Khalid recorded a dose.
/// 3. The person switcher of the top bar, with two people and «إضافة شخص».
///
/// It is a picture: VoiceOver skips it (the title and the line under it say
/// the same), it is drawn at one size and scaled down to the room there is,
/// and the text size setting does not change it. The cards rise into place
/// one after another as [enter] goes from 0 to 1.
class IntroPreview extends StatelessWidget {
  const IntroPreview({super.key, required this.step, required this.enter});

  /// 1, 2 or 3.
  final int step;
  final Animation<double> enter;

  /// The size the pictures are drawn at: an iPhone's width less the margins.
  static const Size canvas = Size(350, 400);

  @override
  Widget build(BuildContext context) {
    final Widget picture = switch (step) {
      1 => _Organize(enter: enter),
      2 => _Share(enter: enter),
      _ => _Follow(enter: enter),
    };
    return ExcludeSemantics(
      child: MediaQuery.withNoTextScaling(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox.fromSize(size: canvas, child: picture),
        ),
      ),
    );
  }
}

/// Page 1: the dark «الجرعة القادمة» card, and under it a reading and a
/// visit, each a little turned.
class _Organize extends StatelessWidget {
  const _Organize({required this.enter});

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

/// Page 2: the members of the circle, and a dark note over them.
class _Share extends StatelessWidget {
  const _Share({required this.enter});

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

/// Page 3: the person switcher of the top bar, and the list it opens.
class _Follow extends StatelessWidget {
  const _Follow({required this.enter});

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
