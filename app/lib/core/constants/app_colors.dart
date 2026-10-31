import 'package:flutter/material.dart';

/// The approved TFAQUD palette: 14 values and nothing else (design system
/// "TFAQUD", Color). One value may serve several roles; do not add a color
/// for a component. Contrast ratios below were computed, not estimated.
///
/// Colors that change with the Increased Contrast setting (secondary text,
/// control borders, status text) are read from `context.tokens` instead.
class AppColors {
  AppColors._();

  // Brand
  /// Primary text, headings, names, primary icons, and the label on [leaf].
  /// 14.99:1 on [surface], 14.06:1 on [canvas], 9.47:1 on [leaf].
  static const Color ink = Color(0xFF202734);

  /// Supporting text, information, focus, strong borders, neutral states.
  /// 10.19:1 on [surface], 9.56:1 on [canvas], 7.69:1 on [line].
  static const Color slate = Color(0xFF36415A);

  /// Fill of the one prominent primary action, always with an [ink] label.
  /// Not a text color (1.58:1 on [surface]).
  static const Color leaf = Color(0xFFB7D894);

  /// Light selection background, always with a dark check mark or indicator.
  static const Color leafTint = Color(0xFFE0F8C7);

  /// Warm accents in brand moments and illustrations. Never a warning.
  static const Color honey = Color(0xFFEEC86B);

  // Neutrals
  /// App background.
  static const Color canvas = Color(0xFFF7F8F5);

  /// Opaque content surfaces, and the opaque fallback of glass.
  static const Color surface = Color(0xFFFFFFFF);

  /// Dividers, decorative borders, disabled fills. 1.33:1 on [surface]:
  /// never the only edge of a control.
  static const Color line = Color(0xFFDDE1D8);

  /// Input borders and supporting icons: 3.98:1 on [surface]. Never text.
  static const Color stone = Color(0xFF7A8275);

  // Functional: always with an icon and a word. Approved on [surface] and
  // [canvas] only; they fail on [leaf].
  /// Success and recorded positive outcomes. 7.10:1 on [surface].
  static const Color success = Color(0xFF286344);

  /// Needs follow-up. 6.59:1 on [surface].
  static const Color warning = Color(0xFF795713);

  /// Input and operation errors only. 6.60:1 on [surface].
  static const Color error = Color(0xFFA53636);

  // Interaction shades of the opaque leaf action. Never applied to glass.
  /// Pointer hover on [leaf]; [ink] label 8.57:1.
  static const Color leafHover = Color(0xFFAECE8C);

  /// Pressed [leaf]; [ink] label 7.76:1.
  static const Color leafPressed = Color(0xFFA4C580);

  /// Dimming layer behind modal sheets and overlays: [ink] at 40%.
  static const Color scrim = Color(0x66202734);
}
