import 'dart:ui' show ImageFilter;

import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
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
///   5. a specular highlight near the top start corner, under the content.
///
/// Use it only for navigation controls: the tab bar, the add button and the
/// top controls. Cards and forms stay on opaque surfaces. Never put glass on
/// glass.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.borderRadius,
    required this.child,
    this.dense = false,
  });

  /// A capsule or a circle: half the height.
  final BorderRadius borderRadius;
  final Widget child;

  /// The nearly opaque glass of a sheet ([AppGlass.denseTop]), so what is
  /// under the sheet does not show through it.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final AppTokens tokens = context.tokens;
    final bool highContrast = MediaQuery.highContrastOf(context);
    final bool opaque = GlassPreferences.opaqueOf(context);
    if (opaque) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: AppSemanticColors.surfaceContent,
          border: Border.all(
            color: highContrast ? tokens.glassBorder : tokens.borderControl,
            width: highContrast
                ? AppGlass.contrastEdgeWidth
                : AppGlass.edgeWidth,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            highContrast ? AppGlass.contrastEdgeWidth : AppGlass.edgeWidth,
          ),
          child: ClipRRect(borderRadius: borderRadius, child: child),
        ),
      );
    }
    return glassBlurSurface(
      borderRadius: borderRadius,
      dense: dense,
      child: child,
    );
  }
}

/// What sits in a glass capsule button: an optional leading circle, the
/// label cut short at one line, and the icon that says it opens something.
List<Widget> glassCapsuleChildren({
  required String label,
  required IconData icon,
  required Widget? leading,
  required VoidCallback? onLeadingPressed,
  required TextTheme text,
}) {
  return <Widget>[
    if (leading != null) ...<Widget>[
      GestureDetector(onTap: onLeadingPressed, child: leading),
      const SizedBox(width: AppSpacing.xs),
    ],
    Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.titleLarge,
      ),
    ),
    const SizedBox(width: AppSpacing.xs),
    Icon(icon, size: AppSizes.iconSmall, color: AppSemanticColors.textPrimary),
  ];
}

/// The translucent path of the glass surface: a soft shadow, a background
/// blur, a fill lighter at the top, a hairline edge with a bright inner rim
/// concentric to it, and a specular highlight near the top start corner.
Widget glassBlurSurface({
  required BorderRadius borderRadius,
  required bool dense,
  required Widget child,
}) {
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
          // Accessible opaque surfaces return above; this is the glass path.
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: dense
                  ? const <Color>[AppGlass.denseTop, AppGlass.denseBottom]
                  : const <Color>[AppGlass.normalTop, AppGlass.normalBottom],
            ),
            border: Border.all(
              color: AppEffects.subtleEdge,
              width: AppGlass.edgeWidth,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppGlass.edgeWidth),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              // Bright inner rim, over the content like a lens edge.
              decoration: BoxDecoration(
                borderRadius: inner,
                border: Border.all(
                  color: AppGlass.innerRim,
                  width: AppGlass.rimWidth,
                ),
              ),
              // The specular highlight lies in the glass, under the
              // content: a dark card in a glass sheet (the + sheet's
              // «سجّل قراءة الآن») keeps its flat color, as in the handoff.
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: inner,
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
    ),
  );
}
