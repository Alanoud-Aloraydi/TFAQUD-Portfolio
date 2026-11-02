import 'package:app/core/constants/app_icons.dart';
import 'package:app/core/navigation/routers.dart';
import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/buttons/pill_button.dart';
import 'package:app/features/auth/presentation/widgets/orbit_painter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One intro page: the colored panel, its picture and its words.
class _Intro {
  const _Intro({
    required this.color,
    required this.titleKey,
    required this.textKey,
    this.icons,
  });

  final Color color;
  final String titleKey;
  final String textKey;

  /// The main icon and three small ones around it. Null draws the brand
  /// orbit of the first page.
  final List<IconData>? icons;
}

/// The welcome: three short pages that say what the app is for, as the
/// Saudi apps people know do it (one idea per page, a big title, two lines,
/// a bold color, dots and one button at the thumb). «التالي» moves on, the
/// last page's «ابدأ» opens the phone number, and «تخطي» goes there at once.
class AuthFeatureScreen extends StatefulWidget {
  const AuthFeatureScreen({super.key});

  @override
  State<AuthFeatureScreen> createState() => _AuthFeatureScreenState();
}

class _AuthFeatureScreenState extends State<AuthFeatureScreen> {
  static const List<_Intro> _pages = <_Intro>[
    _Intro(
      color: AppSemanticColors.accentWarm,
      titleKey: 'auth.app_name',
      textKey: 'auth.tagline',
    ),
    _Intro(
      color: AppSemanticColors.selectedSurface,
      titleKey: 'intro.circle_title',
      textKey: 'intro.circle_text',
      icons: <IconData>[
        AppIcons.users,
        AppIcons.crown,
        AppIcons.userPlus,
        AppIcons.heart,
      ],
    ),
    _Intro(
      color: AppSemanticColors.segmentTrack,
      titleKey: 'intro.plan_title',
      textKey: 'intro.plan_text',
      icons: <IconData>[
        AppIcons.pill,
        AppIcons.alarm,
        AppIcons.heartbeat,
        AppIcons.firstAid,
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

  void _next() {
    if (_last) {
      context.push(Routes.authPhone);
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
    final TextTheme text = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (int page) => setState(() => _page = page),
              itemBuilder: (BuildContext context, int index) =>
                  _IntroPage(intro: _pages[index]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: <Widget>[
                  _Dots(count: _pages.length, current: _page),
                  const SizedBox(height: AppSpacing.xl),
                  PillButton(
                    label: context.tr(_last ? 'auth.start' : 'intro.next'),
                    onPressed: _next,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // The skip link keeps its place on the last page, so the
                  // button does not jump.
                  SizedBox(
                    height: AppSizes.touch,
                    child: _last
                        ? Center(
                            child: Text(
                              context.tr('auth.terms_note'),
                              textAlign: TextAlign.center,
                              style: text.bodySmall,
                            ),
                          )
                        : TextButton(
                            onPressed: () => context.push(Routes.authPhone),
                            child: Text(context.tr('intro.skip')),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A page: the colored panel with its picture, then the title and two lines.
class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.intro});

  final _Intro intro;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<IconData>? icons = intro.icons;
    return Column(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppSpacing.space10),
            ),
            child: ColoredBox(
              color: intro.color,
              child: SafeArea(
                bottom: false,
                child: icons == null
                    ? const _Orbit()
                    : Center(child: _IconCluster(icons: icons)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: <Widget>[
              Semantics(
                header: true,
                child: Text(
                  context.tr(intro.titleKey),
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    fontWeight: AppTextTheme.bold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.tr(intro.textKey),
                textAlign: TextAlign.center,
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

/// The brand orbit of the first page, its mark in the middle of the panel.
class _Orbit extends StatelessWidget {
  const _Orbit();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) =>
          CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: OrbitPainter(centerY: constraints.maxHeight * 0.55),
          ),
    );
  }
}

/// A big white circle with the page's main icon, and three small white
/// circles around it, each with one icon: the picture of the idea.
class _IconCluster extends StatelessWidget {
  const _IconCluster({required this.icons});

  final List<IconData> icons;

  static const double _box = 240;
  static const double _big = 128;
  static const double _small = 56;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: _box,
        height: _box,
        child: Stack(
          children: <Widget>[
            Center(
              child: _Bubble(
                size: _big,
                icon: icons[0],
                iconSize: AppSizes.iconHero,
              ),
            ),
            PositionedDirectional(
              top: AppSpacing.sm,
              start: AppSpacing.lg,
              child: _Bubble(size: _small, icon: icons[1]),
            ),
            PositionedDirectional(
              top: AppSpacing.xl,
              end: 0,
              child: _Bubble(size: _small, icon: icons[2]),
            ),
            PositionedDirectional(
              bottom: AppSpacing.sm,
              start: AppSpacing.xl,
              child: _Bubble(size: _small, icon: icons[3]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.size,
    required this.icon,
    this.iconSize = AppSizes.icon,
  });

  final double size;
  final IconData icon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: AppSemanticColors.textPrimary),
    );
  }
}

/// The page dots: the current one is a longer ink capsule.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  static const double _dot = AppSpacing.sm;
  static const double _long = AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr(
        'common.step_of',
        args: <String>['${current + 1}', '$count'],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (int i = 0; i < count; i++)
            AnimatedContainer(
              duration: AppMotion.fieldFeedback,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              width: i == current ? _long : _dot,
              height: _dot,
              decoration: ShapeDecoration(
                color: i == current
                    ? AppSemanticColors.textPrimary
                    : AppSemanticColors.borderPlan,
                shape: const StadiumBorder(),
              ),
            ),
        ],
      ),
    );
  }
}
