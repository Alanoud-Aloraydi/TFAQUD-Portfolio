import 'dart:math' as math;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/feedback/status_pill.dart';
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
          child: _Rise(enter: enter, order: 0, child: const _NextDoseCard()),
        ),
        Positioned(
          top: 214,
          left: -6,
          right: 18,
          child: _Rise(
            enter: enter,
            order: 1,
            child: _Turned(
              degrees: -2,
              child: _RowCard(
                tile: const _Tile(
                  icon: AppIcons.drop,
                  background: AppSemanticColors.selectedSurface,
                  foreground: AppSemanticColors.statusSuccess,
                ),
                title: context.tr('intro.demo.reading'),
                note: context.tr('intro.demo.reading_note'),
                trailing: StatusPill(
                  text: context.tr('intro.demo.reading_value'),
                  background: AppSemanticColors.selectedSurface,
                  foreground: AppSemanticColors.statusSuccess,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 300,
          left: 18,
          right: -6,
          child: _Rise(
            enter: enter,
            order: 2,
            child: _Turned(
              degrees: 1.5,
              child: _RowCard(
                tile: const _Tile(
                  icon: AppIcons.calendar,
                  background: AppSemanticColors.surfaceAttention,
                  foreground: AppSemanticColors.statusWarning,
                ),
                title: context.tr('intro.demo.visit'),
                note: context.tr('intro.demo.visit_note'),
                trailing: StatusPill(
                  text: context.tr('intro.demo.visit_in'),
                  background: AppSemanticColors.segmentTrack,
                  foreground: AppSemanticColors.textSupporting,
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
    final Widget admin = StatusPill(
      text: context.tr('intro.demo.admin'),
      background: AppSemanticColors.segmentTrack,
      foreground: AppSemanticColors.textSupporting,
    );
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: _Rise(
            enter: enter,
            order: 0,
            child: _FloatingCard(
              child: Column(
                children: <Widget>[
                  _CardHeader(
                    title: context.tr('intro.demo.circle'),
                    note: context.tr('intro.demo.members'),
                  ),
                  _Person(
                    initial: _first(context.tr('intro.demo.reem')),
                    color: AppSemanticColors.selectedSurface,
                    name: context.tr('intro.demo.reem'),
                    note: context.tr('intro.demo.you'),
                    trailing: admin,
                  ),
                  const _Line(),
                  _Person(
                    initial: _first(context.tr('intro.demo.khalid')),
                    color: AppSemanticColors.surfaceAttention,
                    name: context.tr('intro.demo.khalid'),
                    note: context.tr('intro.demo.khalid_note'),
                    trailing: admin,
                  ),
                  const _Line(),
                  _Person(
                    initial: _first(context.tr('intro.demo.nouf')),
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
          child: _Rise(
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
                  _Initial(
                    letter: _first(context.tr('intro.demo.khalid')),
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
                  const _Done(),
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
          child: _Rise(
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
                    _Initial(
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
          child: _Rise(
            enter: enter,
            order: 1,
            child: _FloatingCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _CardHeader(title: context.tr('intro.demo.who')),
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
                      child: _Person(
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
                    child: _Person(
                      initial: context.tr('intro.demo.uncle_initial'),
                      color: AppSemanticColors.selectedSurface,
                      size: 44,
                      name: context.tr('intro.demo.uncle'),
                      note: context.tr('intro.demo.uncle_note'),
                    ),
                  ),
                  const _Line(),
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

/// The dark card of the next dose: the medicine, its time, and a bar of the
/// time left.
class _NextDoseCard extends StatelessWidget {
  const _NextDoseCard();

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: AppSemanticColors.textPrimary,
        shape: AppRadius.shape(AppRadius.l),
        shadows: AppSurfaces.floatShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  context.tr('intro.demo.next_dose'),
                  style: text.labelSmall?.copyWith(
                    color: AppSemanticColors.onInkSupporting,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusPill(
                text: context.tr('intro.demo.next_in'),
                background: AppSemanticColors.surfaceContent.withValues(
                  alpha: 0.14,
                ),
                foreground: AppSemanticColors.surfaceContent,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              const _Tile(
                icon: AppIcons.pill,
                background: AppSemanticColors.selectedSurface,
                foreground: AppSemanticColors.statusSuccess,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      context.tr('intro.demo.medicine'),
                      style: text.titleSmall?.copyWith(
                        color: AppSemanticColors.surfaceContent,
                      ),
                    ),
                    Text(
                      context.tr('intro.demo.medicine_note'),
                      style: text.bodySmall?.copyWith(
                        color: AppSemanticColors.onInkSupporting,
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text: context.tr('intro.demo.medicine_time'),
                      style: text.headlineLarge?.copyWith(
                        color: AppSemanticColors.surfaceContent,
                      ),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: context.tr('intro.demo.evening'),
                      style: text.labelSmall?.copyWith(
                        color: AppSemanticColors.onInkSupporting,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // The time left until the dose: the bar fills from the start side.
          Container(
            height: _bar,
            decoration: ShapeDecoration(
              color: AppSemanticColors.surfaceContent.withValues(alpha: 0.14),
              shape: const StadiumBorder(),
            ),
            alignment: AlignmentDirectional.centerStart,
            child: const FractionallySizedBox(
              widthFactor: 0.72,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: AppSemanticColors.actionPrimary,
                  shape: StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _bar = 6;
}

/// A white card with an icon tile, two lines and a pill at the end.
class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.tile,
    required this.title,
    required this.note,
    required this.trailing,
  });

  final Widget tile;
  final String title;
  final String note;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.floating(AppRadius.m),
      child: Row(
        children: <Widget>[
          tile,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: text.titleSmall),
                Text(note, style: text.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// A white floating card with the rows' side padding.
class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      decoration: AppSurfaces.floating(AppRadius.l),
      child: child,
    );
  }
}

/// The bold title of a card, and a small note at its end.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? small = note;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(title, style: text.titleMedium)),
          if (small != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            Text(small, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// A person: a round letter, the name, a small line under it, and maybe
/// something at the end.
class _Person extends StatelessWidget {
  const _Person({
    required this.initial,
    required this.color,
    required this.name,
    required this.note,
    this.size = AppSizes.avatar,
    this.trailing,
  });

  final String initial;
  final Color color;
  final String name;
  final String note;
  final double size;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final Widget? end = trailing;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          _Initial(letter: initial, color: color, size: size),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(name, style: text.titleSmall),
                Text(note, style: text.bodySmall),
              ],
            ),
          ),
          ?end,
        ],
      ),
    );
  }
}

/// A round letter on a soft color.
class _Initial extends StatelessWidget {
  const _Initial({
    required this.letter,
    required this.color,
    required this.size,
  });

  final String letter;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(color: color, shape: const CircleBorder()),
      child: Text(
        letter,
        style: (size < AppSizes.avatar ? text.labelMedium : text.titleMedium)
            ?.copyWith(
              color: AppSemanticColors.textPrimary,
              fontWeight: AppTextTheme.bold,
            ),
      ),
    );
  }
}

/// A rounded square with an icon, as on the dose and reading cards.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final Color background;
  final Color foreground;

  static const double _size = 42;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: ShapeDecoration(
        color: background,
        shape: AppRadius.shape(AppRadius.s),
      ),
      child: Icon(icon, size: AppSizes.iconSmall, color: foreground),
    );
  }
}

/// The green round check of a recorded dose.
class _Done extends StatelessWidget {
  const _Done();

  static const double _size = 28;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      decoration: const ShapeDecoration(
        color: AppSemanticColors.statusSuccess,
        shape: CircleBorder(),
      ),
      child: const Icon(
        AppIcons.check,
        size: AppSizes.iconSmall - 4,
        color: AppSemanticColors.surfaceContent,
      ),
    );
  }
}

/// The thin line between two rows of a card.
class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: AppSizes.divider,
      thickness: AppSizes.divider,
      color: AppSemanticColors.segmentTrack,
    );
  }
}

/// A card turned by a few degrees.
class _Turned extends StatelessWidget {
  const _Turned({required this.degrees, required this.child});

  final double degrees;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(angle: degrees * math.pi / 180, child: child);
  }
}

/// A card that fades in and rises 18 points into place, after the cards
/// before it ([order] 0 comes first).
class _Rise extends StatelessWidget {
  const _Rise({required this.enter, required this.order, required this.child});

  final Animation<double> enter;
  final int order;
  final Widget child;

  static const double _distance = 18;

  @override
  Widget build(BuildContext context) {
    final Interval curve = Interval(
      order * 0.15,
      order * 0.15 + 0.55,
      curve: AppMotion.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: enter,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final double t = curve.transform(enter.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * _distance),
            child: child,
          ),
        );
      },
    );
  }
}

/// The first letter of a name, for its round letter.
String _first(String name) {
  final String trimmed = name.trim();
  return trimmed.isEmpty ? '' : trimmed.characters.first;
}
