import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

/// Navigation glass with a readable white tint and an opaque accessible mode.
abstract class AppGlass {
  AppGlass._();

  static const Color normalTop = Color(0xE0FFFFFF);
  static const Color normalBottom = Color(0xCCFFFFFF);
  static const Color innerRim = Color(0xD9FFFFFF);
  static const Color clear = Color(0x00FFFFFF);
  static const Color highlight = Color(0x66FFFFFF);
  static const double rimWidth = 1;
  static const double edgeWidth = 0.5;
  static const double contrastEdgeWidth = 1.5;
  static const double segmentInset = 3.5;
  static const double addButtonSize = 56;
  static final Color disabledIcon = AppSemanticColors.textSupporting.withValues(
    alpha: 0.45,
  );
  static final LinearGradient scrollEdge = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      AppSemanticColors.background.withValues(alpha: 0.96),
      AppSemanticColors.background.withValues(alpha: 0.75),
      AppSemanticColors.background.withValues(alpha: 0),
    ],
    stops: const <double>[0, 0.6, 1],
  );

  static Color frostedSurface(Color surface) =>
      surface.withValues(alpha: tintAlpha);

  static List<BoxShadow> tabShadow(Color shadow) => <BoxShadow>[
    BoxShadow(
      color: shadow.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static const double blurSigma = 14;
  static const double tintAlpha = 0.88;

  /// A light, soft shadow under floating glass: ink at 8% and 5%. Cards
  /// have no shadow; they have a 1px line edge (AppSurfaces.card).
  static const List<BoxShadow> shadow = <BoxShadow>[
    BoxShadow(color: Color(0x14202734), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D202734), blurRadius: 2, offset: Offset(0, 1)),
  ];
}
