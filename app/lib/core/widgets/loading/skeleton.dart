import 'package:app/core/theme/materials/surface_style.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/extensions/scroll_insets.dart';
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

/// A line of placeholder text, [widthFactor] of the row's width, from the
/// start (right in Arabic).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.widthFactor = 1, this.height = 14});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: SkeletonBox(height: height),
      ),
    );
  }
}

/// A round placeholder, such as an avatar.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(width: size, height: size, radius: size / 2);
  }
}

/// The white card the real content sits on, holding placeholders.
class SkeletonSurface extends StatelessWidget {
  const SkeletonSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppSurfaces.card(),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// The large title of a tab, and the line under it when [subtitle].
class SkeletonLargeTitle extends StatelessWidget {
  const SkeletonLargeTitle({
    super.key,
    this.width = 112,
    this.subtitle = false,
  });

  final double width;
  final bool subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SkeletonBox(width: width, height: 36, radius: AppRadius.s),
          if (subtitle) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: 104, height: 12),
          ],
        ],
      ),
    );
  }
}

/// A page's skeleton: its own placeholders ([children], in the page's
/// layout) with the shimmer over them. VoiceOver reads «جارٍ التحميل» once.
/// [padding] is the page's own padding; with [scrollInsets] the bars' heights
/// are added, as the page's list does.
class SkeletonPage extends StatelessWidget {
  const SkeletonPage({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.scrollInsets = true,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final bool scrollInsets;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('common.loading'),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: scrollInsets ? context.scrollPadding(padding) : padding,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Placeholders for one part of a page that sits inside a scrolling page,
/// such as a medicine's dose history: the shimmer over a plain column, with
/// no scrolling of its own.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.tr('common.loading'),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Shimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// A form section as `FormGroup` draws it: a header line, then a white card
/// of [rows] rows, each a short label in the label column and a value.
/// [header] false leaves the header out, as for a field on its own.
class SkeletonFormGroup extends StatelessWidget {
  const SkeletonFormGroup({super.key, this.rows = 3, this.header = true});

  final int rows;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (header)
          const Padding(
            padding: EdgeInsetsDirectional.only(
              start: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: SkeletonLine(widthFactor: 0.3, height: 16),
          ),
        SkeletonSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < rows; i++) ...<Widget>[
                if (i > 0) const Divider(height: 1, indent: AppSpacing.lg),
                SizedBox(
                  height: AppSizes.button,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Row(
                      children: <Widget>[
                        const SizedBox(
                          width: AppSizes.formLabel,
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: SkeletonBox(width: 72, height: 16),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        SkeletonBox(width: i.isEven ? 104 : 72, height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A card of rows, each a short label at the start and a value at the end,
/// as the medical file and the account show their details.
class SkeletonDetailsCard extends StatelessWidget {
  const SkeletonDetailsCard({super.key, required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonSurface(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < rows; i++) ...<Widget>[
            if (i > 0)
              const Divider(
                height: 1,
                indent: AppSpacing.lg,
                endIndent: AppSpacing.lg,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  const SkeletonBox(width: 72, height: 16),
                  const Spacer(),
                  SkeletonBox(width: i.isEven ? 96 : 64, height: 16),
                ],
              ),
            ),
          ],
        ],
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
      decoration: AppSurfaces.card(),
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
                  child: SkeletonBox(
                    width: 132,
                    height: 36,
                    radius: AppRadius.s,
                  ),
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
