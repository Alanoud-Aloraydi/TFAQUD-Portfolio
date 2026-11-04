import 'package:flutter/material.dart';

/// Raw palette values. UI roles are defined by the theme, not by consumers.
class AppColors {
  AppColors._();

  /// Main ink for high-contrast text and navigation.
  static const Color ink = Color(0xFF202734);

  /// Secondary ink for supporting text and icons.
  static const Color slate = Color(0xFF36415A);

  /// Primary brand green for actions and success emphasis.
  static const Color leaf = Color(0xFFB7D894);
  static const Color leafHover = Color(0xFFAECE8C);
  static const Color leafPressed = Color(0xFFA4C580);
  static const Color leafTint = Color(0xFFE0F8C7);

  /// Warm accent for prayer and attention states.
  static const Color honey = Color(0xFFEEC86B);
  static const Color honeyLight = Color(0xFFFDF3D6);
  static const Color honeyBorder = Color(0xFFFAEBC6);
  static const Color slateLight = Color(0xFFF6F7F9);
  static const Color slatePale = Color(0xFFDFE2EA);
  static const Color honeyDeep = Color(0xFFB9860F);

  /// Shared canvas behind every app screen.
  static const Color canvas = Color(0xFFF7F8F5);

  /// Foreground surface for cards, sheets, and controls.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFDDE1D8);
  static const Color stone = Color(0xFF7A8275);
  static const Color success = Color(0xFF286344);
  static const Color warning = Color(0xFF795713);
  static const Color error = Color(0xFFA53636);
  // The emergency card's allergy box and the segmented switch (handoff
  // red-100, red-300, navy-100 and navy-300).
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color errorBorder = Color(0xFFF3B4AE);
  static const Color slateMist = Color(0xFFEEF0F4);
  static const Color slateSoft = Color(0xFFC3C8D5);
}
