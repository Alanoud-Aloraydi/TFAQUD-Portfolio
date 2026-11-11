import 'package:app/core/theme/foundations/app_sizes.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';

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
