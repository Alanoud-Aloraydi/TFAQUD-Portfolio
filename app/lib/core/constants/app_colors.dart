import 'package:flutter/material.dart';

/// The TFAQUD palette, "Navy and honey" (design system "TFAQUD", Color):
/// 13 values and nothing else. One value may serve several roles; do not add
/// a color for a component. Contrast ratios below were computed, not
/// estimated.
///
/// Colors that change with the Increased Contrast setting (secondary text,
/// control borders, status text) are read from `context.tokens` instead.
class AppColors {
  AppColors._();

  // Brand
  /// Primary text, headings, names, primary icons, and the fill of the one
  /// primary action (with an [onInk] label).
  /// 14.99:1 on [surface], 14.13:1 on [canvas], 13.2:1 on [honeyTint].
  static const Color ink = Color(0xFF202734);

  /// Label and icons on an [ink] fill: 14.99:1.
  static const Color onInk = Color(0xFFFFFFFF);

  /// Supporting text and information. 7.3:1 on [surface], 6.88:1 on
  /// [canvas], 6.43:1 on [honeyTint], 5.76:1 on [line].
  static const Color slate = Color(0xFF4F566B);

  /// Warm accent: brand moments, illustrations, and the focus ring on [ink]
  /// (9.36:1). Never a warning, and never a ground for status text.
  static const Color honey = Color(0xFFEEC86B);

  /// Light warm tint: selection backgrounds (always with a dark check or
  /// indicator), avatars and quiet highlights. [ink] on it is 13.2:1.
  static const Color honeyTint = Color(0xFFFBF0D2);

  // Neutrals
  /// App background: warm off-white.
  static const Color canvas = Color(0xFFFAF8F4);

  /// Opaque content surfaces, and the opaque fallback of glass.
  static const Color surface = Color(0xFFFFFFFF);

  /// Dividers, decorative borders, disabled fills. 1.27:1 on [surface]:
  /// never the only edge of a control.
  static const Color line = Color(0xFFE8E4DB);

  /// Input borders and supporting icons: 3.98:1 on [surface], 3.75:1 on
  /// [canvas]. Never text.
  static const Color stone = Color(0xFF857F72);

  // Functional: always with an icon and a word. Approved on [surface],
  // [canvas] and [honeyTint]; they fail on [honey].
  /// Success and recorded positive outcomes. 7.10:1 on [surface].
  static const Color success = Color(0xFF286344);

  /// Needs follow-up. 6.59:1 on [surface].
  static const Color warning = Color(0xFF795713);

  /// Input and operation errors only. 6.60:1 on [surface].
  static const Color error = Color(0xFFA53636);

  // Interaction shades of the opaque ink action. Never applied to glass.
  /// Pointer hover on [ink]; [onInk] label 11.21:1.
  static const Color inkHover = Color(0xFF323B4F);

  /// Pressed [ink]; [onInk] label 18.28:1.
  static const Color inkPressed = Color(0xFF11151D);

  /// Dimming layer behind modal sheets and overlays: [ink] at 40%.
  static const Color scrim = Color(0x66202734);
}
