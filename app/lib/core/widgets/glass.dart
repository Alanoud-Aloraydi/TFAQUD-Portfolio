import 'dart:ui' show ImageFilter;

import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Custom Liquid Glass for the navigation layer (design system "TFAQUD",
/// Liquid Glass): a background blur, white at 72%, a thin edge and a soft
/// shadow. Flutter draws its own interface, so this approximates Apple's
/// material; the blur and the tint are starting values to test on a device.
///
/// Use it only for navigation controls: the tab bar, the add button and the
/// top controls. Cards and forms stay on opaque surfaces. Never put glass on
/// glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
  });

  /// A capsule or a circle: half the height.
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool highContrast = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppGlass.shadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppGlass.blurSigma,
            sigmaY: AppGlass.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Increased Contrast: a frostier fill and a slate edge.
              color: AppColors.surface.withValues(
                alpha: highContrast ? 0.9 : AppGlass.tintAlpha,
              ),
              borderRadius: borderRadius,
              border: Border.all(
                color: tokens.glassBorder,
                width: highContrast ? 1.5 : 0.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round glass button of the top controls: account and notifications.
/// [tooltip] is also what VoiceOver reads.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = AppSizes.glassButton,
  });

  final String tooltip;
  final Widget icon;

  /// Null keeps the button visible but inert.
  final VoidCallback? onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(size / 2),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: icon,
          iconSize: AppSizes.icon,
          color: AppColors.ink,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size.square(size)),
        ),
      ),
    );
  }
}
