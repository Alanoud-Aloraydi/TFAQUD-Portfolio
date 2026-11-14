import 'package:flutter/material.dart';

/// Raw palette values. UI roles are defined by the theme, not by consumers.
class AppColors {
  AppColors._();

  /// Main ink for high-contrast text and navigation.
  static const Color ink = Color(0xFF202734);

  /// Secondary ink for supporting text and icons.
  static const Color slate = Color(0xFF36415A);

  /// The brand colour for actions and success emphasis: a light violet of
  /// the same lightness as the sage it replaced, so every contrast the
  /// design system had still holds — ink text on it is 8.9:1 and 13:1 on
  /// its tint (WCAG AA asks 4.5:1).
  ///
  /// The sage it replaced, to go back in one edit: leaf 0xFFA8D5BA,
  /// hover 0xFF9DCDAF, pressed 0xFF91C4A4, tint 0xFFE3F3EA,
  /// canvas 0xFFF6F8F7, line 0xFFDBE3DF.
  static const Color leaf = Color(0xFFC4B5E0);
  static const Color leafHover = Color(0xFFB8A7D9);
  static const Color leafPressed = Color(0xFFAB98D0);
  static const Color leafTint = Color(0xFFEFEAF8);

  /// Warm accent for prayer and attention states.
  static const Color honey = Color(0xFFEEC86B);
  static const Color honeyLight = Color(0xFFFDF3D6);
  static const Color honeyBorder = Color(0xFFFAEBC6);
  static const Color slatePale = Color(0xFFDFE2EA);
  static const Color honeyDeep = Color(0xFFB9860F);

  /// Shared canvas behind every app screen.
  static const Color canvas = Color(0xFFF8F7FB);

  /// Foreground surface for cards, sheets, and controls.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE1DDE9);
  static const Color stone = Color(0xFF74817A);
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
