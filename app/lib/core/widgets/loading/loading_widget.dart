import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

/// A page that is loading. With no [size] it is the page's shimmering
/// skeleton (design system Skeleton), so every loading page shimmers instead
/// of spinning. With a [size] it is a small spinner, for a control that is
/// busy, such as a dose being recorded.
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.size});

  final double? size;

  @override
  Widget build(BuildContext context) {
    final double? spinner = size;
    if (spinner == null) return const PageSkeleton();
    return Center(
      child: LoadingAnimationWidget.discreteCircle(
        secondRingColor: AppSemanticColors.accentWarm,
        thirdRingColor: AppSemanticColors.accentLeaf,
        color: AppSemanticColors.textPrimary,
        size: spinner,
      ),
    );
  }
}
