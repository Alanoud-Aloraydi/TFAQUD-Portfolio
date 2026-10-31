import 'package:flutter/material.dart';

/// The TFAQUD palette (design system "TFAQUD", Color): the team's approved
/// values and nothing else. Navy ([ink]) is the main color: text and the one
/// primary action. Honey and the greens are accents that stay small: green
/// only as light selections, avatars and small marks, never as a button fill.
/// One value may serve several roles; do not add a color for a component.
/// Contrast ratios below were computed, not estimated.
///
/// Colors that change with the Increased Contrast setting (secondary text,
/// control borders, status text) are read from `context.tokens` instead.
class AppColors {
  AppColors._();

  // Brand
  /// Oxford Blue. Primary text, headings, names, primary icons, and the fill
  /// of the one primary action (with an [onInk] label).
  /// 14.99:1 on [surface], 14.06:1 on [canvas], 13.15:1 on [leafTint].
  static const Color ink = Color(0xFF202734);

  /// Label and icons on an [ink] or [slate] fill: 14.99:1 and 10.19:1.
  static const Color onInk = Color(0xFFFFFFFF);

  /// Charcoal. Supporting text and information, and the pressed shade of the
  /// ink action. 10.19:1 on [surface], 9.56:1 on [canvas], 7.69:1 on [line].
  static const Color slate = Color(0xFF36415A);

  /// Tea Green. A small accent for illustrations and marks. Never a button
  /// fill, never text (1.58:1 on [surface]).
  static const Color leaf = Color(0xFFB7D894);

  /// Pale green. Selection backgrounds (always with a dark check or
  /// indicator), the selected tab, avatars and quiet highlights. [ink] on it
  /// is 13.15:1; it is only 1.14:1 on [surface], so it never marks a
  /// selection by itself.
  static const Color leafTint = Color(0xFFE0F8C7);

  /// Saffron. Warm accent: brand moments, illustrations, and the focus ring
  /// on [ink] (9.36:1). Never a warning, and never a ground for status text.
  static const Color honey = Color(0xFFEEC86B);

  // Neutrals
  /// App background: very light, with a slight green bias.
  static const Color canvas = Color(0xFFF7F8F5);

  /// Opaque content surfaces, and the opaque fallback of glass.
  static const Color surface = Color(0xFFFFFFFF);

  /// Dividers, decorative borders, disabled fills. 1.33:1 on [surface]:
  /// never the only edge of a control.
  static const Color line = Color(0xFFDDE1D8);

  /// Input borders and supporting icons: 3.98:1 on [surface], 3.73:1 on
  /// [canvas]. Never text.
  static const Color stone = Color(0xFF7A8275);

  // Functional: always with an icon and a word. Approved on [surface],
  // [canvas] and [leafTint]; they fail on [leaf] and [honey].
  /// Success and recorded positive outcomes. 7.10:1 on [surface].
  static const Color success = Color(0xFF286344);

  /// Needs follow-up. 6.59:1 on [surface].
  static const Color warning = Color(0xFF795713);

  /// Input and operation errors only. 6.60:1 on [surface].
  static const Color error = Color(0xFFA53636);

  /// Dimming layer behind modal sheets and overlays: [ink] at 40%.
  static const Color scrim = Color(0x66202734);
}
