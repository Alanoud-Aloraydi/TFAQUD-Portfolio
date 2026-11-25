import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/utils/scroll_insets.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:app/core/widgets/loading/skeleton_card.dart';
import 'package:app/core/widgets/loading/tfaqud_loader.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

/// A page that is loading. With no [size] it is the page's shimmering
/// skeleton (design system Skeleton), so every loading page shimmers instead
/// of spinning. With a [size] it is the app's turning logo ([TfaqudLoader]),
/// for a screen or a control that is busy, such as a dose being recorded.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final double? spinner = size;
    if (spinner == null) return const PageSkeleton();
    return Center(child: TfaqudLoader(size: spinner));
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
      label: spoken(context.tr('common.loading')),
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
