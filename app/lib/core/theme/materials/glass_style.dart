import 'package:app/core/theme/materials/surface_style.dart';
import 'package:flutter/material.dart';

/// Starting values of the custom glass (blur, white tint). They are values to
/// test on a device, not approved colors.
abstract class AppGlass {
  AppGlass._();

  static const double blurSigma = 14;
  static const double tintAlpha = 0.72;

  /// A light, soft shadow under floating glass: ink at 8% and 5%. Cards
  /// have no shadow; they have a 1px line edge (AppSurfaces.card).
  static const List<BoxShadow> shadow = <BoxShadow>[
    BoxShadow(color: Color(0x14202734), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0D202734), blurRadius: 2, offset: Offset(0, 1)),
  ];
}
