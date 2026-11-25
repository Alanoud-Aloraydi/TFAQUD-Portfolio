import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:app/core/localization/spoken_arabic.dart';
import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_menu_row.dart';
import 'package:flutter/material.dart';

/// The open menu (see [showGlassMenu]). Public so tests can find its rows.
class GlassMenu extends StatefulWidget {
  const GlassMenu({
    super.key,
    required this.anchor,
    required this.sections,
    required this.semanticLabel,
    required this.animation,
    this.anchorContent,
  });

  final Rect anchor;
  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;
  final Animation<double> animation;
  final Widget? anchorContent;

  @override
  State<GlassMenu> createState() => _GlassMenuState();
}

class _GlassMenuState extends State<GlassMenu> {
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: widget.animation,
    curve: AppMotion.menuSpring,
    reverseCurve: AppMotion.easeInCubic,
  );

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final GlassMenuLayout layout = GlassMenuLayout.of(
          context,
          constraints,
          widget.anchor,
          widget.sections,
        );
        return GlassMenuSurface(
          anchor: widget.anchor,
          layout: layout,
          curve: _curve,
          animation: widget.animation,
          semanticLabel: widget.semanticLabel,
          anchorContent: widget.anchorContent,
          rows: GlassMenuRows(
            sections: widget.sections,
            rowHeight: layout.row,
            width: layout.width,
            height: layout.height - layout.edge,
          ),
        );
      },
    );
  }
}

/// The rows at their final size; the glass around them clips them while it
/// grows.
class GlassMenuRows extends StatelessWidget {
  const GlassMenuRows({
    super.key,
    required this.sections,
    required this.rowHeight,
    required this.width,
    required this.height,
  });

  final List<List<GlassMenuEntry>> sections;
  final double rowHeight;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return OverflowBox(
      alignment: Alignment.topCenter,
      minWidth: width,
      maxWidth: width,
      minHeight: height,
      maxHeight: height,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int s = 0; s < sections.length; s++) ...<Widget>[
                if (s > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    child: Divider(
                      height: AppSizes.divider,
                      color: AppEffects.subtleEdge,
                    ),
                  ),
                for (final GlassMenuEntry entry in sections[s])
                  GlassMenuRow(entry: entry, height: rowHeight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The glass of the open menu while it opens and closes: it grows from the
/// control's rectangle to the menu's, the [rows] come into focus and the
/// control's own content ([anchorContent]) blurs away.
class GlassMenuSurface extends StatelessWidget {
  const GlassMenuSurface({
    super.key,
    required this.anchor,
    required this.layout,
    required this.curve,
    required this.animation,
    required this.semanticLabel,
    required this.rows,
    this.anchorContent,
  });

  final Rect anchor;
  final GlassMenuLayout layout;
  final Animation<double> curve;
  final Animation<double> animation;
  final String semanticLabel;
  final Widget rows;
  final Widget? anchorContent;

  @override
  Widget build(BuildContext context) {
    final bool still = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: curve,
      builder: (BuildContext context, Widget? _) {
        final GlassMenuMotion m = GlassMenuMotion(
          anchor: anchor,
          layout: layout,
          still: still,
          t: still ? 1 : curve.value,
          animationValue: animation.value,
        );
        return Stack(
          children: <Widget>[
            Positioned.fromRect(
              rect: m.rect,
              child: Semantics(
                scopesRoute: true,
                namesRoute: true,
                explicitChildNodes: true,
                label: spoken(semanticLabel),
                child: GlassSurface(
                  borderRadius: BorderRadius.all(Radius.circular(m.radius)),
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        if (anchorContent != null && m.anchorOut > 0)
                          GlassMenuAnchorLayer(
                            fade: m.anchorOut,
                            content: anchorContent!,
                          ),
                        Positioned(
                          top: 0,
                          left: (m.rect.width - layout.width) / 2,
                          width: layout.width,
                          height: layout.height - layout.edge,
                          child: Opacity(
                            opacity: m.rowsIn,
                            child: Transform.scale(
                              alignment: Alignment.topCenter,
                              scale: m.scale,
                              child: glassMenuBlurred(m.blur, rows),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// [child] blurred by [sigma]; unchanged when the blur would not show.
Widget glassMenuBlurred(double sigma, Widget child) {
  if (sigma < 0.2) return child;
  return ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    child: child,
  );
}

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
