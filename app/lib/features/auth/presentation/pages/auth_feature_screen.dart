import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/intro_memory.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/auth/presentation/widgets/intro_previews.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// One welcome page: the two soft glows behind it, and its words: the step
/// (نظّم، شارك، تابع), a title and one line.
class _Intro {
  const _Intro({
    required this.glowHigh,
    required this.glowLow,
    required this.stepKey,
    required this.titleKey,
    required this.bodyKey,
  });

  /// The glow at the top corner, and the one lower on the other side.
  final Color glowHigh;
  final Color glowLow;
  final String stepKey;
  final String titleKey;
  final String bodyKey;
}

/// The welcome: three pages that show the app itself. Each has a picture
/// of real parts of the app with example data (the next dose, the circle,
/// the person switcher) over soft glows, then the step, a title and one
/// line. At the bottom, in reach of the thumb: «تخطي», the dots of the
/// pages, and «التالي». The last page has «ابدأ», which opens the phone
/// number; «تخطي» goes there at once.
class AuthFeatureScreen extends StatefulWidget {
  const AuthFeatureScreen({super.key});

  @override
  State<AuthFeatureScreen> createState() => _AuthFeatureScreenState();
}

class _AuthFeatureScreenState extends State<AuthFeatureScreen> {
  static const List<_Intro> _pages = <_Intro>[
    _Intro(
      glowHigh: AppSemanticColors.introGlowWarm,
      glowLow: AppSemanticColors.introGlowLeaf,
      stepKey: 'intro.p1_step',
      titleKey: 'intro.p1_title',
      bodyKey: 'intro.p1_body',
    ),
    _Intro(
      glowHigh: AppSemanticColors.introGlowLeaf,
      glowLow: AppSemanticColors.introGlowWarm,
      stepKey: 'intro.p2_step',
      titleKey: 'intro.p2_title',
      bodyKey: 'intro.p2_body',
    ),
    _Intro(
      glowHigh: AppSemanticColors.introGlowMist,
      glowLow: AppSemanticColors.introGlowCalm,
      stepKey: 'intro.p3_step',
      titleKey: 'intro.p3_title',
      bodyKey: 'intro.p3_body',
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;

  bool get _last => _page == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    // Nobody is signed in on the welcome (after a sign-out, an ended sign-in
    // or a deleted account): what was the last person's goes.
    unawaited(forgetSignedOutPerson());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// «ابدأ» and «تخطي»: the welcome is done for this install
  /// ([IntroMemory]), and the phone number page opens.
  void _start() {
    unawaited(IntroMemory.markSeen());
    context.push(Routes.authPhone);
  }

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

  /// The glows behind the pages, mixed between two pages while one slides
  /// over the other.
  (Color, Color) _glows() {
    final double raw = _controller.hasClients
        ? (_controller.page ?? _page.toDouble())
        : _page.toDouble();
    final double page = raw.clamp(0, _pages.length - 1).toDouble();
    final int from = page.floor();
    final int to = math.min(from + 1, _pages.length - 1);
    final double t = page - from;
    final _Intro a = _pages[from];
    final _Intro b = _pages[to];
    return (
      Color.lerp(a.glowHigh, b.glowHigh, t) ?? a.glowHigh,
      Color.lerp(a.glowLow, b.glowLow, t) ?? a.glowLow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every page is light, so the status bar icons are dark.
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppSemanticColors.introCanvas,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final (Color high, Color low) = _glows();
                  return _Glows(high: high, low: low);
                },
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  // The app's name stays while the pages slide.
                  SizedBox(
                    height: AppSizes.touch,
                    child: Center(
                      child: Text(
                        context.tr('auth.app_name'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      // The cards' soft shadows show past the pages' edge.
                      clipBehavior: Clip.none,
                      itemCount: _pages.length,
                      onPageChanged: (int page) => setState(() => _page = page),
                      itemBuilder: (BuildContext context, int index) =>
                          _IntroPage(
                            intro: _pages[index],
                            step: index + 1,
                            active: index == _page,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
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
                          : _Controls(
                              key: const ValueKey<String>('controls'),
                              count: _pages.length,
                              current: _page,
                              onSkip: _start,
                              onNext: _next,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two soft round glows on the page: one at the top corner and one lower on
/// the other side, as on the pictures of the welcome.
class _Glows extends StatelessWidget {
  const _Glows({required this.high, required this.low});

  final Color high;
  final Color low;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned(top: 90, right: -60, child: _Glow(color: high, size: 300)),
        Positioned(top: 300, left: -70, child: _Glow(color: low, size: 240)),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
            stops: const <double>[0.4, 1],
          ),
        ),
      ),
    );
  }
}

/// The bottom of the first pages: «تخطي», the dots, and «التالي».
class _Controls extends StatelessWidget {
  const _Controls({
    super.key,
    required this.count,
    required this.current,
    required this.onSkip,
    required this.onNext,
  });

  final int count;
  final int current;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: AppSemanticColors.textSupporting,
            minimumSize: const Size(AppSizes.touch, AppSizes.touch),
          ),
          child: Text(context.tr('intro.skip')),
        ),
        Expanded(
          child: Center(
            child: _Dots(count: count, current: current),
          ),
        ),
        FilledButton(
          onPressed: onNext,
          style: FilledButton.styleFrom(
            backgroundColor: AppSemanticColors.textPrimary,
            foregroundColor: AppSemanticColors.surfaceContent,
            shape: const StadiumBorder(),
            minimumSize: const Size(AppSizes.button, AppSizes.button),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(context.tr('intro.next')),
              const SizedBox(width: AppSpacing.sm),
              const Icon(AppIcons.next, size: AppSizes.iconSmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// The dots of the pages: the page on show is a longer ink bar. VoiceOver
/// reads «الخطوة 1 من 3».
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  static const double _dot = 7;
  static const double _on = 24;

  @override
  Widget build(BuildContext context) {
    final Duration duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppMotion.contentEnter;
    return Semantics(
      label: context.tr(
        'common.step_of',
        args: <String>['${current + 1}', '$count'],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < count; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: AppSpacing.tight),
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.easeOutCubic,
              width: i == current ? _on : _dot,
              height: _dot,
              decoration: ShapeDecoration(
                color: i == current
                    ? AppSemanticColors.textPrimary
                    : AppSemanticColors.introDotIdle,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A page: the picture, and under it the step, the title and one line. When
/// the page shows, the picture's cards rise into place one after another;
/// this plays once each time, and not at all with Reduce Motion. The
/// picture takes the room the words leave.
class _IntroPage extends StatefulWidget {
  const _IntroPage({
    required this.intro,
    required this.step,
    required this.active,
  });

  final _Intro intro;

  /// 1, 2 or 3.
  final int step;

  /// Whether this is the page on show.
  final bool active;

  @override
  State<_IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<_IntroPage>
    with SingleTickerProviderStateMixin {
  /// The most of the page the words take. With very large text they stop
  /// here and scroll, so the picture keeps the rest.
  static const double _wordsShare = 0.6;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.introEnter,
  );

  bool _reduceMotion = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _enter.value = 1;
    } else if (!_started && widget.active) {
      _play();
    }
    _started = true;
  }

  @override
  void didUpdateWidget(_IntroPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  void _play() {
    if (_reduceMotion) {
      _enter.value = 1;
    } else {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: IntroPreview(step: widget.step, enter: _enter),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: box.maxHeight * _wordsShare),
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _Words(intro: widget.intro, step: widget.step),
            ),
          ),
        ],
      ),
    );
  }
}

/// The words of a page: a small white pill with the step («01 · نظّم»),
/// the title and one line.
class _Words extends StatelessWidget {
  const _Words({required this.intro, required this.step});

  final _Intro intro;
  final int step;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: const ShapeDecoration(
            color: AppSemanticColors.surfaceContent,
            shape: StadiumBorder(),
            shadows: AppSurfaces.floatShadow,
          ),
          child: Text(
            '${step.toString().padLeft(2, '0')} · ${context.tr(intro.stepKey)}',
            style: text.labelMedium?.copyWith(
              color: AppSemanticColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Semantics(
          header: true,
          child: Text(context.tr(intro.titleKey), style: text.displaySmall),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          context.tr(intro.bodyKey),
          style: text.bodyLarge?.copyWith(
            color: AppSemanticColors.textSupporting,
          ),
        ),
      ],
    );
  }
}
