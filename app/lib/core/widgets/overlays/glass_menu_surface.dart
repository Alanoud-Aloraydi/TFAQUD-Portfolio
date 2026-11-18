import 'package:app/core/l10n/spoken_arabic.dart';
import 'package:app/core/widgets/navigation/glass.dart';
import 'package:app/core/widgets/overlays/glass_menu_anchor_layer.dart';
import 'package:app/core/widgets/overlays/glass_menu_blur.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_menu_motion.dart';
import 'package:flutter/material.dart';

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
