import 'package:app/core/theme/foundations/app_motion.dart';
import 'package:app/core/widgets/overlays/glass_menu.dart';
import 'package:app/core/widgets/overlays/glass_menu_entry.dart';
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
