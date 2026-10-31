import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/extensions/scroll_insets.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// Shimmer (design system Skeleton): a soft light band that sweeps over
/// the grey placeholder shapes of [child], from right to left in Arabic, every
/// 1.4 seconds. With Reduce Motion on, the shapes stay still.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (BuildContext context, Widget? child) {
        // The band travels from one side to the other, past both edges.
        final double travel = -1.5 + 3 * _controller.value;
        final double x = rtl ? -travel : travel;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) => LinearGradient(
            begin: Alignment(x - 0.6, -0.2),
            end: Alignment(x + 0.6, 0.2),
            colors: const <Color>[
              Color(0x00FFFFFF),
              Color(0xB3FFFFFF),
              Color(0x00FFFFFF),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// A grey placeholder shape. [width] null fills the row.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: AppColors.line,
          shape: AppRadius.shape(radius),
        ),
      ),
    );
  }
}

/// A placeholder of a content card: a tile, two lines and a detail line, on
/// the same white card as the real one.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: AppRadius.shape(AppRadius.l),
        shadows: AppGlass.cardShadow,
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                SkeletonBox(width: 40, height: 40, radius: AppRadius.s),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: SkeletonBox(height: 16),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      FractionallySizedBox(
                        widthFactor: 0.4,
                        child: SkeletonBox(height: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            FractionallySizedBox(
              widthFactor: 0.5,
              child: SkeletonBox(height: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// The loading state of a page: shimmering placeholders in the page's shape
/// instead of a spinner, so the page does not jump when its content comes.
/// [title] draws the large title (and [subtitle] the line under it),
/// [filter] the segmented control, then [cards] content cards.
class PageSkeleton extends StatelessWidget {
  const PageSkeleton({
    super.key,
    this.title = false,
    this.subtitle = false,
    this.filter = false,
    this.cards = 3,
  });

  final bool title;
  final bool subtitle;
  final bool filter;
  final int cards;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('common.loading'),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: context.scrollPadding(const EdgeInsets.all(AppSpacing.lg)),
            children: <Widget>[
              if (title) ...<Widget>[
                const Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SkeletonBox(width: 132, height: 36, radius: AppRadius.s),
                ),
                if (subtitle) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SkeletonBox(width: 96, height: 12),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
              if (filter) ...<Widget>[
                const SkeletonBox(
                  height: AppSizes.touch,
                  radius: AppSizes.touch / 2,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              for (int i = 0; i < cards; i++) ...<Widget>[
                if (i > 0) const SizedBox(height: AppSpacing.md),
                const SkeletonCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades from one state of a page to the next (loading, content, error), so
/// content comes in smoothly instead of popping in. [stateKey] names the
/// state; a change of key starts the fade. With Reduce Motion on, the change
/// is instant.
class ContentSwitcher extends StatelessWidget {
  const ContentSwitcher({
    super.key,
    required this.stateKey,
    required this.child,
  });

  final Object stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 280),
      reverseDuration: still ? Duration.zero : const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previous, if (current != null) current],
      ),
      child: KeyedSubtree(key: ValueKey<Object>(stateKey), child: child),
    );
  }
}
