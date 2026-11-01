import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:flutter/material.dart';

/// The app's opaque card (design system Card): surface, the iOS smooth
/// corner, and a 1px `line` edge in place of a shadow. Cards on the canvas
/// need an edge (surface is only 1.07:1 there); a thin line is lighter and
/// crisper than a blurred shadow.
abstract class AppSurfaces {
  AppSurfaces._();

  static const BorderSide edge = BorderSide(color: AppColors.line);

  static ShapeBorder cardShape([double radius = AppRadius.card]) =>
      AppRadius.shape(radius, side: edge);

  static ShapeDecoration card([double radius = AppRadius.card]) =>
      ShapeDecoration(color: AppColors.surface, shape: cardShape(radius));
}
