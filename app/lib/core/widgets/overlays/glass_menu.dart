import 'dart:math' as math;
import 'dart:ui' show ImageFilter, lerpDouble;

import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:app/core/widgets/overlays/glass_menu_rows.dart';
import 'package:flutter/material.dart';

/// Positions the glass menu above the current route.
class GlassMenuRoute extends PopupRoute<Object?> {
  GlassMenuRoute({
    required this.anchor,
    required this.sections,
    required this.semanticLabel,
    this.anchorContent,
  });

  final Rect anchor;
  final List<List<GlassMenuEntry>> sections;
  final String semanticLabel;
  final Widget? anchorContent;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => semanticLabel;

  @override
  Duration get transitionDuration => AppMotion.menuEnter;

  @override
  Duration get reverseTransitionDuration => AppMotion.menuExit;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return GlassMenu(
      anchor: anchor,
      sections: sections,
      semanticLabel: semanticLabel,
      animation: animation,
      anchorContent: anchorContent,
    );
  }
}

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

  static const double _minWidth = 248;
  static const double _separator = 1 + 2 * AppSpacing.xs;

  /// Height of one row: at least 48, more with larger text.
  static double rowHeight(BuildContext context) => math.max(
    AppSizes.touch + AppSpacing.xs,
    MediaQuery.textScalerOf(context).scale(28) + 2 * AppSpacing.sm,
  );

  @override
  State<GlassMenu> createState() => _GlassMenuState();

  static Widget _blurred(double sigma, Widget child) {
    if (sigma < 0.2) return child;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
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
    final Rect anchor = widget.anchor;
    final List<List<GlassMenuEntry>> sections = widget.sections;
    final Animation<double> animation = widget.animation;
    final Widget? anchorContent = widget.anchorContent;
    final bool still = MediaQuery.disableAnimationsOf(context);
    final bool highContrast = MediaQuery.highContrastOf(context);
    final double row = GlassMenu.rowHeight(context);
    final int rows = sections.fold(
      0,
      (int n, List<GlassMenuEntry> s) => n + s.length,
    );
    final double edge = highContrast ? 3 : 1;
    final double height =
        2 * AppSpacing.sm +
        rows * row +
        (sections.length - 1) * GlassMenu._separator +
        edge;
    final CurvedAnimation curve = _curve;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double room = constraints.maxWidth - 2 * AppSpacing.lg;
        final double width = math.min(
          math.max(anchor.width + 96, GlassMenu._minWidth),
          room,
        );
        final double left = (anchor.center.dx - width / 2).clamp(
          AppSpacing.lg,
          constraints.maxWidth - AppSpacing.lg - width,
        );
        final double bottomInset =
            MediaQuery.paddingOf(context).bottom + AppSpacing.lg;
        final double maxTop = math.max(
          AppSpacing.lg,
          constraints.maxHeight - bottomInset - height,
        );
        // Open downward from the anchor when there is room below it;
        // otherwise flip to grow upward so low anchors never clip rows
        // off the bottom of the screen.
        final double top = anchor.top > maxTop
            ? math.max(AppSpacing.lg, anchor.bottom - height)
            : anchor.top;
        final Rect target = Rect.fromLTWH(
          left,
          math.min(top, maxTop),
          width,
          height,
        );
        final Widget rowsColumn = GlassMenuRows(
          sections: sections,
          rowHeight: row,
          width: width,
          height: height - edge,
        );

        return AnimatedBuilder(
          animation: curve,
          builder: (BuildContext context, Widget? _) {
            final double t = still ? 1 : curve.value;
            // The glass: from the control's rectangle to the menu's, with
            // the spring's small overshoot.
            final Rect rect = Rect.lerp(anchor, target, t)!;
            final double radius = lerpDouble(
              anchor.shortestSide / 2,
              AppRadius.l,
              t.clamp(0.0, 1.0),
            )!.clamp(0.0, rect.shortestSide / 2);
            // The rows come into focus fast; the control's own content
            // blurs away even faster.
            final double rowsIn = still
                ? animation.value
                : (t * 2.2).clamp(0.0, 1.0);
            final double blur = still ? 0 : (1 - rowsIn) * 8;
            final double anchorOut = still ? 0 : (1 - t * 4).clamp(0.0, 1.0);
            final double scale = (rect.width / width).clamp(0.5, 1.06);

            return Stack(
              children: <Widget>[
                Positioned.fromRect(
                  rect: rect,
                  child: Semantics(
                    scopesRoute: true,
                    namesRoute: true,
                    explicitChildNodes: true,
                    label: widget.semanticLabel,
                    child: GlassSurface(
                      borderRadius: BorderRadius.all(Radius.circular(radius)),
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            if (anchorContent != null && anchorOut > 0)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Opacity(
                                    opacity: anchorOut,
                                    child: GlassMenu._blurred(
                                      (1 - anchorOut) * 6,
                                      Center(child: anchorContent),
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 0,
                              left: (rect.width - width) / 2,
                              width: width,
                              height: height - edge,
                              child: Opacity(
                                opacity: rowsIn,
                                child: Transform.scale(
                                  alignment: Alignment.topCenter,
                                  scale: scale,
                                  child: GlassMenu._blurred(blur, rowsColumn),
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
      },
    );
  }
}
