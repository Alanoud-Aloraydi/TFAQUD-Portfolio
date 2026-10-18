import 'package:flutter/material.dart';

/// Raw palette, light theme only. Derived by rule (OKLCH, brand hue 224.5),
/// not copied from Figma. Contrast ratios were computed, not estimated.
class AppColors {
  AppColors._();

  // Surfaces
  static const Color background = Color(0xFFF3F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sunken = Color(0xFFE3EBEF);

  // Lines
  /// Decorative only (1.32:1 on surface). Never the only boundary of a control.
  static const Color line = Color(0xFFD8E2E6);

  /// Control borders: 3.34:1 on surface, 3.12:1 on background.
  static const Color fieldBorder = Color(0xFF808F95);

  // Ink
  static const Color ink = Color(0xFF021F2A); // 17.05:1 on surface
  static const Color ink2 = Color(0xFF354F59); // 8.7:1 on surface
  static const Color ink3 = Color(0xFF546A73); // 5.7:1 surface, 5.32:1 background

  // Brand
  static const Color brand = Color(0xFF03607A); // 7.1:1 with white
  static const Color brandTint = Color(0xFFE1F4FB); // brand on it: 6.27:1
  static const Color onBrand = Color(0xFFFFFFFF);

  // Status: never rely on color alone (add an icon or a label).
  static const Color success = Color(0xFF1D865A); // 4.56:1 on surface
  static const Color successInk = Color(0xFF155D3E); // 7.01:1 on successTint
  static const Color successTint = Color(0xFFDAF9E7);
  static const Color danger = Color(0xFFC94D45); // 4.53:1 on surface, 4.24:1 on background
  static const Color dangerInk = Color(0xFF8A332D); // 8.1:1 on surface
  static const Color dangerTint = Color(0xFFFEEBE9); // dangerInk on it: 7.05:1
  static const Color warningInk = Color(0xFF6F4806); // 7.05:1 on warningTint
  static const Color warningTint = Color(0xFFFFEDD9);

  // Overlay (ink with 40% alpha)
  static const Color scrim = Color(0x66021F2A);

  /// Kept only because loading_widget.dart still reads it.
  static const Color secondary = ink2;
}
