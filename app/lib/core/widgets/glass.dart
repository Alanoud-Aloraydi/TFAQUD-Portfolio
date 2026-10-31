import 'dart:ui' show ImageFilter;

import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Custom Liquid Glass for the navigation layer (design system "TFAQUD",
/// Liquid Glass). Flutter draws its own interface, so this builds the look
/// from layers, outside in:
///   1. a soft shadow that lifts the control off the content;
///   2. a background blur of whatever scrolls underneath;
///   3. a translucent fill, lighter at the top, so content shows through;
///   4. a hairline outer edge that keeps the shape visible on a plain
///      background, and a bright inner rim, concentric with it;
///   5. a specular highlight near the top start corner.
/// The values are starting points to test on a device, not approved colors.
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

  static const double _rim = 1;
  static const double _edge = 0.5;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool highContrast = MediaQuery.highContrastOf(context);
    // The inner rim sits inside the hairline edge: its radius is the outer
    // radius minus the edge width, so the two stay concentric.
    final BorderRadius inner =
        borderRadius - const BorderRadius.all(Radius.circular(_edge));

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
            // Fill and hairline edge. With Increased Contrast the fill is
            // frostier and the edge is a solid slate line, as Apple does.
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: highContrast
                    ? const <Color>[Color(0xF2FFFFFF), Color(0xE6FFFFFF)]
                    : const <Color>[Color(0xB8FFFFFF), Color(0x73FFFFFF)],
              ),
              border: Border.all(
                color: highContrast ? tokens.glassBorder : const Color(0x1F202734),
                width: highContrast ? 1.5 : _edge,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(highContrast ? 1.5 : _edge),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                // Bright inner rim and the specular highlight.
                decoration: BoxDecoration(
                  borderRadius: inner,
                  border: Border.all(
                    color: highContrast
                        ? const Color(0x00FFFFFF)
                        : const Color(0xD9FFFFFF),
                    width: _rim,
                  ),
                  gradient: const RadialGradient(
                    center: AlignmentDirectional(-0.55, -0.85),
                    radius: 0.9,
                    colors: <Color>[Color(0x66FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
                child: child,
              ),
            ),
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
          style: IconButton.styleFrom(shape: const CircleBorder()),
        ),
      ),
    );
  }
}
