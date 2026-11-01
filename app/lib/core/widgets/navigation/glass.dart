import 'dart:ui' show ImageFilter;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_effects.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/theme/materials/glass_style.dart';
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

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool highContrast = MediaQuery.highContrastOf(context);
    // The inner rim sits inside the hairline edge: its radius is the outer
    // radius minus the edge width, so the two stay concentric.
    final BorderRadius inner =
        borderRadius -
        const BorderRadius.all(Radius.circular(AppGlass.edgeWidth));

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
                    ? const <Color>[
                        AppGlass.contrastTop,
                        AppGlass.contrastBottom,
                      ]
                    : const <Color>[AppGlass.normalTop, AppGlass.normalBottom],
              ),
              border: Border.all(
                color: highContrast
                    ? tokens.glassBorder
                    : AppEffects.subtleEdge,
                width: highContrast
                    ? AppGlass.contrastEdgeWidth
                    : AppGlass.edgeWidth,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                highContrast ? AppGlass.contrastEdgeWidth : AppGlass.edgeWidth,
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                // Bright inner rim and the specular highlight.
                decoration: BoxDecoration(
                  borderRadius: inner,
                  border: Border.all(
                    color: highContrast ? AppGlass.clear : AppGlass.innerRim,
                    width: AppGlass.rimWidth,
                  ),
                  gradient: const RadialGradient(
                    center: AlignmentDirectional(-0.55, -0.85),
                    radius: 0.9,
                    colors: <Color>[AppGlass.highlight, AppGlass.clear],
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
          color: AppSemanticColors.textPrimary,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tight(Size.square(size)),
          style: IconButton.styleFrom(shape: const CircleBorder()),
        ),
      ),
    );
  }
}

/// Glass capsule with a short label and an icon after it, such as the circle
/// switcher in the middle of the top bar. At least 44 high. [semanticLabel]
/// is what VoiceOver reads, so a long name cut short on screen is still read
/// in full.
class GlassCapsuleButton extends StatelessWidget {
  const GlassCapsuleButton({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final IconData icon;

  /// Null keeps the capsule visible but inert.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      onTap: onPressed,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSizes.touch,
          minWidth: AppSizes.touch,
        ),
        child: GlassSurface(
          borderRadius: const BorderRadius.all(
            Radius.circular(AppSizes.touch / 2),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              customBorder: const StadiumBorder(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleLarge,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      icon,
                      size: AppSizes.iconSmall,
                      color: AppSemanticColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
