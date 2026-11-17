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

  /// A step between the page and [leafTint]: the folding groups of
  /// «السجل», which sit on the page itself and would vanish in its colour
  /// but read as the page's own tint rather than a block of their own.
  static const Color leafMist = Color(0xFFF4F0FA);

  /// One step down from [leafTint], for a group that gathers cards: the
  /// tint itself reads 1.11 on the canvas, near enough to vanish, while
  /// this reads 1.36 and still leaves white cards on it at 1.45.
  static const Color leafTintDeep = Color(0xFFDCD2F0);

  /// Ink of the violet's own family, for words and marks that sit on a
  /// violet or honey surface: 6.4 on leaf, 8.3 on honey, 10.3 on leafTint.
  static const Color inkViolet = Color(0xFF3F2A65);

  /// Warm accent for prayer and attention states. The hue is 50, a little
  /// cooler than the gold that went with the sage, because yellow is the
  /// violet's complement and a warmer, more saturated one shouts over it.
  /// The gold it replaced, to go back in one edit: honey 0xFFEEC86B,
  /// light 0xFFFDF3D6, border 0xFFFAEBC6, deep 0xFFB9860F.
  static const Color honey = Color(0xFFE8D67D);
  static const Color honeyLight = Color(0xFFFDF7D9);
  static const Color honeyBorder = Color(0xFFF9F1C7);

  /// «يحتاج انتباهك», the folding groups of «السجل», and the simplified
  /// mode's «هل أخذت هذا الدواء؟»: a cream paler than [honeyLight], and its
  /// soft beige edge.
  static const Color cream = Color(0xFFFCF5ED);
  static const Color creamEdge = Color(0xFFEDE4D6);
  static const Color slatePale = Color(0xFFDFE2EA);

  /// Icons on white, never text: 3.3 against white, over the 3:1 that
  /// non-text graphics need.
  static const Color honeyDeep = Color(0xFFA58C0D);

  /// Shared canvas behind every app screen.
  static const Color canvas = Color(0xFFF8F7FB);

  /// Foreground surface for cards, sheets, and controls.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFE1DDE9);
  static const Color stone = Color(0xFF74817A);

  /// Status greens and blues, each on its own hue so no two badges wear
  /// the same chip: success 152, info 200. The green that went with the
  /// sage was 0xFF286344.
  static const Color success = Color(0xFF1C6E48);
  static const Color successLight = Color(0xFFE7F8F0);
  static const Color info = Color(0xFF23688B);
  static const Color infoLight = Color(0xFFE7F3F8);
  static const Color warning = Color(0xFF795713);
  static const Color error = Color(0xFFA53636);
  // The emergency card's allergy box and the segmented switch (handoff
  // red-100, red-300, navy-100 and navy-300).
  static const Color errorLight = Color(0xFFFDECEA);
  static const Color errorBorder = Color(0xFFF3B4AE);
  static const Color slateMist = Color(0xFFEEF0F4);
  static const Color slateSoft = Color(0xFFC3C8D5);
}
