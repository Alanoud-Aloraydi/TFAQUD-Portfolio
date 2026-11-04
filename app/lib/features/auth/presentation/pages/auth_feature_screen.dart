import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/core/widgets/illustrations/guide_owl.dart';
import 'package:app/features/medications/domain/dose_reminders.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// One welcome page: the color behind it, the owl's pose, and what the owl
/// says: the step (نظّم، شارك، تابع), a title and one line.
class _Intro {
  const _Intro({
    required this.tint,
    required this.pose,
    required this.stepKey,
    required this.titleKey,
    required this.bodyKey,
  });

  final Color tint;
  final OwlPose pose;
  final String stepKey;
  final String titleKey;
  final String bodyKey;
}

/// The welcome: the app's guide, a wise owl, explains the app in three
/// steps that belong together: organize, share, follow. Each page has the
/// owl in a pose and a speech bubble with what it says. Story bars at the
/// top show how far along you are, the color behind follows your finger
/// from page to page, and one round button at the thumb moves on. The last
/// page has «ابدأ», which opens the phone number; «تخطي» goes there at once.
class AuthFeatureScreen extends StatefulWidget {
  const AuthFeatureScreen({super.key});

  @override
  State<AuthFeatureScreen> createState() => _AuthFeatureScreenState();
}

class _AuthFeatureScreenState extends State<AuthFeatureScreen> {
  static const List<_Intro> _pages = <_Intro>[
    _Intro(
      tint: AppSemanticColors.introWarm,
      pose: OwlPose.organize,
      stepKey: 'intro.p1_step',
      titleKey: 'intro.p1_title',
      bodyKey: 'intro.p1_body',
    ),
    _Intro(
      tint: AppSemanticColors.introLeaf,
      pose: OwlPose.share,
      stepKey: 'intro.p2_step',
      titleKey: 'intro.p2_title',
      bodyKey: 'intro.p2_body',
    ),
    _Intro(
      tint: AppSemanticColors.introCalm,
      pose: OwlPose.follow,
      stepKey: 'intro.p3_step',
      titleKey: 'intro.p3_title',
      bodyKey: 'intro.p3_body',
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;
  bool _precached = false;

  bool get _last => _page == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    // Nobody is signed in on the welcome (after a sign-out, an ended sign-in
    // or a deleted account): the dose reminders of the last person go.
    unawaited(GetIt.I<DoseReminders>().clear());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      GuideOwl.precache(context);
    }
  }

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

  /// The color behind the pages, mixed between two pages while one slides
  /// over the other.
  Color _tint() {
    final double raw = _controller.hasClients
        ? (_controller.page ?? _page.toDouble())
        : _page.toDouble();
    final double page = raw.clamp(0, _pages.length - 1).toDouble();
    final int from = page.floor();
    final int to = math.min(from + 1, _pages.length - 1);
    return Color.lerp(_pages[from].tint, _pages[to].tint, page - from) ??
        _pages[from].tint;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every page is light, so the status bar icons are dark.
      value: SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) =>
            ColoredBox(color: _tint(), child: child),
        child: Scaffold(
          backgroundColor: AppSemanticColors.transparent,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                // The bars, the name and «تخطي» stay while the pages slide.
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _TopBar(
                    count: _pages.length,
                    current: _page,
                    onSkip: _last ? null : _start,
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    // The bubble's soft shadow shows past the pages' edge.
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
                        : _NextButton(
                            key: const ValueKey<String>('next'),
                            progress: (_page + 1) / _pages.length,
                            onPressed: _next,
                          ),
                  ),
                ),
              ],
            ),
          ),
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
    required this.onSkip,
  });

  final int count;
  final int current;

  /// Null on the last page, where «ابدأ» is the way on.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final VoidCallback? skip = onSkip;
    const Color ink = AppSemanticColors.textPrimary;
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
                      color: i <= current ? ink : ink.withValues(alpha: 0.2),
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

/// A page: the owl in its pose, and under it the speech bubble with what it
/// says. When the page shows, the owl rises into place and the bubble opens
/// from its tail; this plays once each time, and not at all with Reduce
/// Motion. The owl takes the room the bubble leaves.
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
  /// How far the owl rises as it arrives.
  static const double _rise = 24;

  /// The most of the page the bubble takes. With very large text it stops
  /// here and scrolls, so the owl keeps the rest.
  static const double _bubbleShare = 0.62;

  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: AppMotion.guideEnter,
  );

  // The owl fades in and rises with a soft spring; a moment later the
  // bubble fades in and grows from its tail.
  late final CurvedAnimation _owlFade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.4, curve: AppMotion.easeOut),
  );
  late final CurvedAnimation _owlRise = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0, 0.7, curve: AppMotion.alertSpring),
  );
  late final CurvedAnimation _bubbleFade = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.35, 0.75, curve: AppMotion.easeOut),
  );
  late final CurvedAnimation _bubbleGrow = CurvedAnimation(
    parent: _enter,
    curve: const Interval(0.35, 1, curve: AppMotion.alertSpring),
  );
  late final Animation<double> _bubbleScale = Tween<double>(
    begin: 0.94,
    end: 1,
  ).animate(_bubbleGrow);

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
    _owlFade.dispose();
    _owlRise.dispose();
    _bubbleFade.dispose();
    _bubbleGrow.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) => Column(
          children: <Widget>[
            Expanded(
              child: FadeTransition(
                opacity: _owlFade,
                child: AnimatedBuilder(
                  animation: _owlRise,
                  builder: (BuildContext context, Widget? child) {
                    final double t = _owlRise.value;
                    return Transform.translate(
                      offset: Offset(0, (1 - t) * _rise),
                      child: Transform.scale(
                        scale: 0.92 + 0.08 * t,
                        alignment: Alignment.bottomCenter,
                        child: child,
                      ),
                    );
                  },
                  // The owl stands just above its bubble; spare room goes
                  // above it.
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GuideOwl(pose: widget.intro.pose),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _bubbleFade,
              child: ScaleTransition(
                scale: _bubbleScale,
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: box.maxHeight * _bubbleShare,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    // The bubble's shadow shows past the scroll area.
                    clipBehavior: Clip.none,
                    child: _SpeechBubble(
                      intro: widget.intro,
                      step: widget.step,
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

/// What the owl says: a white bubble with a small tail up to the owl. In it
/// the step («01» and نظّم), the title, and one line.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.intro, required this.step});

  final _Intro intro;
  final int step;

  /// The tail's height and half its width.
  static const double _tail = 12;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      children: <Widget>[
        const CustomPaint(
          size: Size(_tail * 2, _tail),
          painter: _TailPainter(),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.inset),
          decoration: AppSurfaces.floating(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    decoration: const ShapeDecoration(
                      color: AppSemanticColors.textPrimary,
                      shape: StadiumBorder(),
                    ),
                    child: Text(
                      step.toString().padLeft(2, '0'),
                      style: text.labelMedium?.copyWith(
                        color: AppSemanticColors.surfaceContent,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    context.tr(intro.stepKey),
                    style: text.titleSmall?.copyWith(
                      color: AppSemanticColors.textSupporting,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(
                  context.tr(intro.titleKey),
                  style: text.headlineMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.tr(intro.bodyKey),
                style: text.bodyLarge?.copyWith(
                  color: AppSemanticColors.textSupporting,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The bubble's tail: a small triangle with a round tip, pointing up.
class _TailPainter extends CustomPainter {
  const _TailPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double mid = size.width / 2;
    final Path tail = Path()
      // One point below the bottom, so it joins the bubble without a seam.
      ..moveTo(0, size.height + 1)
      ..lineTo(mid - 3, 2)
      ..quadraticBezierTo(mid, 0, mid + 3, 2)
      ..lineTo(size.width, size.height + 1)
      ..close();
    canvas.drawPath(tail, Paint()..color = AppSemanticColors.surfaceContent);
  }

  @override
  bool shouldRepaint(_TailPainter old) => false;
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

/// Draws the onboarding progress ring.
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
        ..color = AppSemanticColors.textPrimary.withValues(alpha: 0.12),
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
