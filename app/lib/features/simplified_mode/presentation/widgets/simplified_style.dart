import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/theme/foundations/app_spacing.dart';
import 'package:app/features/simplified_mode/presentation/widgets/simplified_colors.dart';
import 'package:flutter/material.dart';

/// The simplified mode's own scale over the app's tokens: larger type
/// (nothing below 18), bigger touch targets and one big action height, for
/// a patient who reads and taps less easily. Its colors are
/// [SimplifiedColors].
abstract final class SimplifiedStyle {
  // Layout.
  static const double page = AppSpacing.space5;
  static const double gap = AppSpacing.lg;
  static const double pad = AppSpacing.space5;
  static const double radius = AppRadius.l;

  /// The smallest tap target of the mode.
  static const double touch = 56;

  /// The height of a main action («أخذته الآن»).
  static const double action = 72;

  /// A round answer of a full-screen reminder.
  static const double answer = 104;

  // Type sizes.
  static const double caption = 18;
  static const double body = 20;
  static const double title = 22;
  static const double headline = 24;
  static const double name = 30;
  static const double display = 32;
  static const double hero = 40;
  static const double time = 44;
  static const double number = 56;

  static TextStyle head(
    double size, {
    Color color = SimplifiedColors.ink,
    double height = 1.25,
  }) => TextStyle(
    fontSize: size,
    fontWeight: AppTextTheme.bold,
    color: color,
    height: height,
  );

  static TextStyle label(double size, {Color color = SimplifiedColors.ink}) =>
      TextStyle(
        fontSize: size,
        fontWeight: AppTextTheme.semibold,
        color: color,
        height: 1.3,
      );

  static TextStyle text(
    double size, {
    Color color = SimplifiedColors.muted,
    FontWeight weight = AppTextTheme.regular,
  }) =>
      TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.5);
}
