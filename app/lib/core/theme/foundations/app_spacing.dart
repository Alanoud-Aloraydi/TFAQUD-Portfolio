/// Spacing scale of the design system: a 4px base, mostly 8px steps.
/// The short names were here first; the design-system names say the same.
abstract class AppSpacing {
  AppSpacing._();

  static const double xs = 4; // space-1
  static const double sm = 8; // space-2
  static const double md = 12; // space-3
  static const double lg = 16; // space-4: screen margin, card padding
  static const double xl = 24; // space-6: between cards and form fields
  static const double xxl = 32; // space-8: between sections

  static const double space1 = xs;
  static const double space2 = sm;
  static const double space3 = md;
  static const double space4 = lg;

  /// Side padding of large buttons.
  static const double space5 = 20;
  static const double space6 = xl;
  static const double space8 = xxl;

  /// Above a screen's first section and around empty states.
  static const double space10 = 40;

  /// Centers a 4-point line in a 16-point row: (16 - 4) / 2. Not a gap.
  static const double tight = 6;
}
