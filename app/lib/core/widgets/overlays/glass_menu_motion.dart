import 'dart:ui' show lerpDouble;

import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_menu_surface.dart';
import 'package:flutter/material.dart';

/// One frame of the glass menu opening or closing, worked out from the
/// spring's value [t].
class GlassMenuMotion {
  GlassMenuMotion({
    required Rect anchor,
    required GlassMenuLayout layout,
    required this.still,
    required double t,
    required double animationValue,
  }) {
    // The glass: from the control's rectangle to the menu's, with
    // the spring's small overshoot.
    rect = Rect.lerp(anchor, layout.target, t)!;
    radius = lerpDouble(
      anchor.shortestSide / 2,
      AppRadius.l,
      t.clamp(0.0, 1.0),
    )!.clamp(0.0, rect.shortestSide / 2);
    // The rows come into focus fast; the control's own content
    // blurs away even faster.
    rowsIn = still ? animationValue : (t * 2.2).clamp(0.0, 1.0);
    blur = still ? 0 : (1 - rowsIn) * 8;
    anchorOut = still ? 0 : (1 - t * 4).clamp(0.0, 1.0);
    scale = (rect.width / layout.width).clamp(0.5, 1.06);
  }

  /// Reduce Motion is on: the menu appears at once and only fades.
  final bool still;

  late final Rect rect;
  late final double radius;
  late final double rowsIn;
  late final double blur;
  late final double anchorOut;
  late final double scale;
}

/// The control's own content, drawn over the opening menu and fading and
/// blurring away as the menu grows; [fade] is its opacity.
class GlassMenuAnchorLayer extends StatelessWidget {
  const GlassMenuAnchorLayer({
    super.key,
    required this.fade,
    required this.content,
  });

  final double fade;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: fade,
          child: glassMenuBlurred((1 - fade) * 6, Center(child: content)),
        ),
      ),
    );
  }
}
