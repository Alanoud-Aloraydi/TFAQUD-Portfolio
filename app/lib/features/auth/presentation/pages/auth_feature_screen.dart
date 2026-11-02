import 'dart:math' as math;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/illustrations/saturn_mascot.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// One intro page: the color of its panel, the headline with its circled
/// word, the line under the character, the character's mood and what rides
/// its ring.
class _Intro {
  const _Intro({
    required this.panel,
    required this.ink,
    required this.circle,
    required this.lineKey,
    required this.wordKey,
    required this.subKey,
    required this.mood,
    required this.orbiters,
    this.beforeKey,
    this.afterKey,
  });

  final Color panel;

  /// Text on the panel: ink on light panels, white on the ink panel.
  final Color ink;

  /// The hand-drawn oval around the circled word.
  final Color circle;

  final String lineKey;
  final String? beforeKey;
  final String wordKey;
  final String? afterKey;
  final String subKey;
  final MascotMood mood;
  final List<Widget> orbiters;

  bool get dark => ink == AppSemanticColors.surfaceContent;
}

/// The welcome: three pages with the app's character, a small Saturn whose
/// ring goes around the people and things it cares for (the circle of the
/// app's name). Like the welcome of the apps people know (Arabic ones
/// included): story bars at the top, a bold color with a soft wave, a big
/// headline with one word circled by hand, one short line, and one round
/// button at the thumb that shows how far along you are. The last page has
/// «ابدأ», which opens the phone number; «تخطي» goes there at once.
class AuthFeatureScreen extends StatefulWidget {
  const AuthFeatureScreen({super.key});

  @override
  State<AuthFeatureScreen> createState() => _AuthFeatureScreenState();
}

class _AuthFeatureScreenState extends State<AuthFeatureScreen> {
  static const List<_Intro> _pages = <_Intro>[
    _Intro(
      panel: AppSemanticColors.accentWarm,
      ink: AppSemanticColors.textPrimary,
      circle: AppSemanticColors.textPrimary,
      lineKey: 'intro.p1_line',
      beforeKey: 'intro.p1_before',
      wordKey: 'intro.p1_word',
      afterKey: 'intro.p1_after',
      subKey: 'intro.p1_sub',
      mood: MascotMood.happy,
      orbiters: <Widget>[
        MascotBadge(
          icon: AppIcons.heart,
          iconColor: AppSemanticColors.statusError,
        ),
        MascotBadge(icon: AppIcons.heartbeat),
        MascotBadge(icon: AppIcons.calendarCheck),
      ],
    ),
    _Intro(
      panel: AppSemanticColors.textPrimary,
      ink: AppSemanticColors.surfaceContent,
      circle: AppSemanticColors.accentWarm,
      lineKey: 'intro.p2_line',
      wordKey: 'intro.p2_word',
      subKey: 'intro.p2_sub',
      mood: MascotMood.calm,
      orbiters: <Widget>[
        MascotBadge(letter: 'ر', color: AppSemanticColors.selectedSurface),
        MascotBadge(letter: 'خ', color: AppSemanticColors.surfaceAttention),
        MascotBadge(letter: 'ن', color: AppSemanticColors.borderPlan),
      ],
    ),
    _Intro(
      panel: AppSemanticColors.accentLeaf,
      ink: AppSemanticColors.textPrimary,
      circle: AppSemanticColors.surfaceContent,
      lineKey: 'intro.p3_line',
      wordKey: 'intro.p3_word',
      subKey: 'intro.p3_sub',
      mood: MascotMood.sure,
      orbiters: <Widget>[
        MascotBadge(icon: AppIcons.pill),
        MascotBadge(icon: AppIcons.alarm),
        MascotBadge(
          icon: AppIcons.firstAid,
          iconColor: AppSemanticColors.statusError,
        ),
      ],
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;

  bool get _last => _page == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() => context.push(Routes.authPhone);

  void _next() {
    if (_last) {
      _start();
      return;
    }
    // Reduce Motion: the next page shows at once.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(
        duration: AppMotion.contentEnter,
        curve: AppMotion.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _Intro intro = _pages[_page];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status bar icons on the ink panel, dark on the others.
      value: intro.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppSemanticColors.surfaceContent,
        body: Stack(
          children: <Widget>[
            PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (int page) => setState(() => _page = page),
              itemBuilder: (BuildContext context, int index) =>
                  _IntroPage(intro: _pages[index]),
            ),
            // The bars, the name and «تخطي» stay while the pages slide.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
                child: _TopBar(
                  count: _pages.length,
                  current: _page,
                  ink: intro.ink,
                  onSkip: _last ? null : _start,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: AnimatedSwitcher(
                    duration: AppMotion.contentEnter,
                    child: _last
                        ? Column(
                            key: const ValueKey<String>('start'),
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              PillButton(
                                label: context.tr('auth.start'),
                                onPressed: _start,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                context.tr('auth.terms_note'),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          )
                        : _NextButton(
                            key: const ValueKey<String>('next'),
                            progress: (_page + 1) / _pages.length,
                            onPressed: _next,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Story bars, the app's name and «تخطي».
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.current,
    required this.ink,
    required this.onSkip,
  });

  final int count;
  final int current;
  final Color ink;

  /// Null on the last page, where «ابدأ» is the way on.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final VoidCallback? skip = onSkip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          label: context.tr(
            'common.step_of',
            args: <String>['${current + 1}', '$count'],
          ),
          child: Row(
            children: <Widget>[
              for (int i = 0; i < count; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AnimatedContainer(
                    duration: AppMotion.contentEnter,
                    height: AppSpacing.xs,
                    decoration: ShapeDecoration(
                      color: i <= current ? ink : ink.withValues(alpha: 0.25),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: AppSizes.touch,
          child: Row(
            children: <Widget>[
              Text(
                context.tr('auth.app_name'),
                style: text.titleMedium?.copyWith(color: ink),
              ),
              const Spacer(),
              if (skip != null)
                TextButton(
                  onPressed: skip,
                  style: TextButton.styleFrom(foregroundColor: ink),
                  child: Text(context.tr('intro.skip')),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A page: the colored panel with a soft wave and the headline, the
/// character on white below it, and one short line.
class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.intro});

  final _Intro intro;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double height = box.maxHeight;
        final double width = box.maxWidth;
        final double panel = height * 0.34;
        final double radius = math.min(width * 0.27, height * 0.13);
        // The character stands on white, just under the wave.
        final double mascotTop = panel + radius * 0.05;
        return Stack(
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: panel + _WaveClipper.depth,
              child: ClipPath(
                clipper: _WaveClipper(),
                child: ColoredBox(color: intro.panel),
              ),
            ),
            Positioned(
              top: safe.top + AppSpacing.sm + AppSpacing.xs + AppSizes.touch,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              child: _Headline(intro: intro),
            ),
            ..._sparkles(width, panel),
            Positioned(
              top: mascotTop,
              left: 0,
              right: 0,
              child: Center(
                child: SaturnMascot(
                  radius: radius,
                  mood: intro.mood,
                  orbiters: intro.orbiters,
                ),
              ),
            ),
            Positioned(
              top: mascotTop + radius * 2.5 + AppSpacing.lg,
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              child: Text(
                context.tr(intro.subKey),
                textAlign: TextAlign.center,
                style: text.bodyLarge?.copyWith(
                  color: AppSemanticColors.textSupporting,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Small four-point sparkles around the character, in the page's color.
  List<Widget> _sparkles(double width, double panel) {
    final Color color = intro.dark
        ? AppSemanticColors.accentWarm
        : intro.panel;
    const List<(double, double, double)> spots = <(double, double, double)>[
      (0.14, 0.18, 14.0),
      (0.86, 0.12, 10.0),
      (0.9, 0.62, 16.0),
      (0.12, 0.62, 10.0),
    ];
    return <Widget>[
      for (final (double x, double y, double size) in spots)
        Positioned(
          left: width * x - size / 2,
          top: panel + panel * y,
          width: size,
          height: size,
          child: CustomPaint(painter: _SparklePainter(color)),
        ),
    ];
  }
}

/// The headline: a first line, then a line with one word circled by hand
/// (the word is its own run, so the oval goes around it only).
class _Headline extends StatelessWidget {
  const _Headline({required this.intro});

  final _Intro intro;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.displaySmall?.copyWith(color: intro.ink);
    final String? before = intro.beforeKey;
    final String? after = intro.afterKey;
    return Semantics(
      header: true,
      label: <String>[
        context.tr(intro.lineKey),
        if (before != null) context.tr(before),
        context.tr(intro.wordKey),
        if (after != null) context.tr(after),
      ].join(' '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(context.tr(intro.lineKey), style: style),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            children: <Widget>[
              if (before != null) Text(context.tr(before), style: style),
              CustomPaint(
                foregroundPainter: _HandOvalPainter(intro.circle),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(context.tr(intro.wordKey), style: style),
                ),
              ),
              if (after != null) Text(context.tr(after), style: style),
            ],
          ),
        ],
      ),
    );
  }
}

/// A hand-drawn oval: one loop around the word and a short overlap where
/// the pen meets its start.
class _HandOvalPainter extends CustomPainter {
  const _HandOvalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final Rect oval = Rect.fromLTWH(0, 2, size.width, size.height - 2);
    canvas.drawArc(oval, 0.95 * math.pi, 2 * math.pi - 0.01, false, pen);
    canvas.drawArc(
      oval.inflate(3).translate(0, -2),
      0.88 * math.pi,
      0.22 * math.pi,
      false,
      pen,
    );
  }

  @override
  bool shouldRepaint(_HandOvalPainter old) => old.color != color;
}

/// A four-point sparkle.
class _SparklePainter extends CustomPainter {
  const _SparklePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double r = size.width / 2;
    final Path star = Path()
      ..moveTo(cx, cy - r)
      ..quadraticBezierTo(cx, cy, cx + r, cy)
      ..quadraticBezierTo(cx, cy, cx, cy + r)
      ..quadraticBezierTo(cx, cy, cx - r, cy)
      ..quadraticBezierTo(cx, cy, cx, cy - r)
      ..close();
    canvas.drawPath(star, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.color != color;
}

/// The soft wave at the bottom of the panel.
class _WaveClipper extends CustomClipper<Path> {
  /// How far the wave dips below the panel's line.
  static const double depth = 40;

  @override
  Path getClip(Size size) {
    final double w = size.width;
    final double y = size.height - depth;
    return Path()
      ..lineTo(w, 0)
      ..lineTo(w, y - 10)
      ..cubicTo(w * 0.78, y + 34, w * 0.58, y - 46, w * 0.36, y - 6)
      ..cubicTo(w * 0.18, y + 26, w * 0.08, y + 6, 0, y - 18)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

/// The round «التالي»: an ink circle with an arrow, inside a ring that
/// fills as the pages go by.
class _NextButton extends StatelessWidget {
  const _NextButton({
    super.key,
    required this.progress,
    required this.onPressed,
  });

  /// From 0 to 1.
  final double progress;
  final VoidCallback onPressed;

  static const double _outer = 76;
  static const double _inner = 60;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr('intro.next'),
      excludeSemantics: true,
      onTap: onPressed,
      child: SizedBox(
        width: _outer,
        height: _outer,
        child: CustomPaint(
          painter: _ProgressRingPainter(progress),
          child: Center(
            child: Material(
              color: AppSemanticColors.textPrimary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPressed,
                child: const SizedBox(
                  width: _inner,
                  height: _inner,
                  child: Icon(
                    AppIcons.next,
                    color: AppSemanticColors.surfaceContent,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect circle = Offset.zero & size;
    final Rect ring = circle.deflate(2);
    canvas.drawOval(
      ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppSemanticColors.borderPlan,
    );
    canvas.drawArc(
      ring,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppSemanticColors.textPrimary,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}
