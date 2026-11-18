import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
import 'package:app/core/widgets/overlays/glass_menu_layout.dart';
import 'package:app/core/widgets/overlays/glass_menu_rows.dart';
import 'package:app/core/widgets/overlays/glass_menu_surface.dart';
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

  /// Height of one row: at least 48, more with larger text.
  static double rowHeight(BuildContext context) =>
      GlassMenuLayout.rowHeight(context);

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
