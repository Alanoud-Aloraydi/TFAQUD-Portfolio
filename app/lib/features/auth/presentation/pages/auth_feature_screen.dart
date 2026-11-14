import 'dart:async';
import 'dart:math' as math;

import 'package:app/core/navigation/routers.dart';
import 'package:app/core/services/signed_out.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/components/navigation_themes.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/auth/domain/repositories/welcome_memory.dart';
import 'package:app/features/auth/presentation/widgets/auth_controls.dart';
import 'package:app/features/auth/presentation/widgets/auth_glows.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro.dart';
import 'package:app/features/auth/presentation/widgets/auth_intro_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

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
  static const List<AuthIntro> _pages = <AuthIntro>[
    AuthIntro(
      glowHigh: AppSemanticColors.introGlowWarm,
      glowLow: AppSemanticColors.introGlowLeaf,
      stepKey: 'intro.p1_step',
      titleKey: 'intro.p1_title',
      bodyKey: 'intro.p1_body',
    ),
    AuthIntro(
      glowHigh: AppSemanticColors.introGlowLeaf,
      glowLow: AppSemanticColors.introGlowWarm,
      stepKey: 'intro.p2_step',
      titleKey: 'intro.p2_title',
      bodyKey: 'intro.p2_body',
    ),
    AuthIntro(
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
  /// ([WelcomeMemory]), and the phone number page opens.
  void _start() {
    unawaited(GetIt.I<WelcomeMemory>().markSeen());
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
    final AuthIntro a = _pages[from];
    final AuthIntro b = _pages[to];
    return (
      Color.lerp(a.glowHigh, b.glowHigh, t) ?? a.glowHigh,
      Color.lerp(a.glowLow, b.glowLow, t) ?? a.glowLow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Every page is light, so the status bar icons are dark.
      value: AppNavigationThemes.systemBars,
      child: Scaffold(
        backgroundColor: AppSemanticColors.introCanvas,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  final (Color high, Color low) = _glows();
                  return AuthGlows(high: high, low: low);
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
                          AuthIntroPage(
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
                          : AuthControls(
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
