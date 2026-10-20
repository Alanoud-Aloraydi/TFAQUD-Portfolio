import 'package:app/core/constants/app_colors.dart';
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
          ModalBarrier(
            color: AppColors.background.withAlpha(225),
            dismissible: false,
          ),
          Center(
            child: LoadingAnimationWidget.discreteCircle(
              secondRingColor: AppColors.secondary,
              thirdRingColor: AppColors.ink3,
              color: AppColors.brand,
              size: 50,
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

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key, this.size = 50});
  final double? size;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingAnimationWidget.discreteCircle(
        secondRingColor: AppColors.secondary,
        thirdRingColor: AppColors.ink3,
        color: AppColors.brand,
        size: size ?? 50,
      ),
    );
  }
}

