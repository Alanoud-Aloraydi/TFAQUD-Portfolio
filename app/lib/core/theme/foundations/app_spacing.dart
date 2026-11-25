import 'package:app/core/theme/foundations/app_sizes.dart';

/// Spacing scale of the design system: a 4px base, mostly 8px steps.
/// The short names were here first; the design-system names say the same.
abstract class AppSpacing {
  AppSpacing._();

  static const double xs = 4; // space-1
  static const double sm = 8; // space-2
  static const double md = 12; // space-3
  static const double lg = 16; // space-4: screen margin, card padding
  static const double xl = 24; // space-6: between cards and form fields

  static const double space2 = sm;
  static const double space4 = lg;

  /// Side padding of large buttons.
  static const double space5 = 20;

  /// Above a screen's first section and around empty states.
  static const double space10 = 40;

  /// The spacing rule of every screen (Apple's inset grouped layout):
  ///
  /// * [inset]: text inside any box (card, tile, row, field, sheet) keeps
  ///   16 from the box's edges. Rows of a list keep 16 at the sides and 12
  ///   above and below; capsules keep 12 at the sides.
  /// * [labelGap]: a label or header outside a box sits 8 from it. A small
  ///   header (13 to 17) starts 16 in, lined up with the text inside the
  ///   box; a section title (22) starts at the box's edge.
  static const double inset = lg;
  static const double labelGap = sm;

  /// Centers a 4-point line in a 16-point row: (16 - 4) / 2. Not a gap.
  static const double tight = 6;
}

/// Measures shared by every row and card that shows one piece of care
/// (a dose, a measurement, an appointment) in «اليوم», «الخطة» and «السجل».
abstract final class AppItemCard {
  AppItemCard._();

  /// Padding inside a plan or record card.
  static const double padding = AppSpacing.lg;

  /// Gap between the parts of a row or card.
  static const double gap = AppSpacing.sm;

  /// Gap between two cards in a list.
  static const double listGap = AppSpacing.md;

  /// Width of the time column of a Today row at normal text size.
  static const double timeColumn = 48;

  /// The round kind icon or photo at the start of a row.
  static const double leading = AppSizes.avatar;

  /// Smallest height of anything tappable in a row.
  static const double touch = AppSizes.button;

  /// Above this text scale the status drops under the title instead of
  /// squeezing it.
  static const double stackedTextScale = 1.3;
}
