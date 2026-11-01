import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/loading/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingWidgetOverlay {
  OverlayEntry? _overlayEntry;

  // Singleton instance
  static final LoadingWidgetOverlay _instance =
      LoadingWidgetOverlay._internal();

  factory LoadingWidgetOverlay() {
    return _instance;
  }

  LoadingWidgetOverlay._internal();

  void show(BuildContext context) {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          ModalBarrier(color: AppEffects.loadingScrim, dismissible: false),
          Center(
            child: LoadingAnimationWidget.discreteCircle(
              secondRingColor: AppSemanticColors.accentWarm,
              thirdRingColor: AppSemanticColors.accentLeaf,
              color: AppSemanticColors.textPrimary,
              size: AppSizes.loadingIndicator,
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void hide() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

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
