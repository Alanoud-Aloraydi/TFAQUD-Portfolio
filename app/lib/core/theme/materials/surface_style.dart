import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';

/// The app's opaque card (design system Card): surface, the iOS smooth
/// corner, and a 1px `line` edge in place of a shadow. Cards on the canvas
/// need an edge (surface is only 1.07:1 there); a thin line is lighter and
/// crisper than a blurred shadow.
abstract class AppSurfaces {
  AppSurfaces._();

  static const BorderSide edge = BorderSide(
    color: AppSemanticColors.borderSubtle,
  );

  static ShapeBorder cardShape([double radius = AppRadius.card]) =>
      AppRadius.shape(radius, side: edge);

  static ShapeDecoration card([double radius = AppRadius.card]) =>
      ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: cardShape(radius),
      );

  /// A white card that floats over a tinted page with no edge, such as the
  /// guide owl's speech bubble: a soft ink shadow below it (ink at 8%).
  static const List<BoxShadow> floatShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14202734), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static ShapeDecoration floating([double radius = AppRadius.card]) =>
      ShapeDecoration(
        color: AppSemanticColors.surfaceContent,
        shape: AppRadius.shape(radius),
        shadows: floatShadow,
      );
}
