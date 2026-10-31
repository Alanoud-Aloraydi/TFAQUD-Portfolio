import 'package:app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Type scale of the design system, set in IBM Plex Sans Arabic.
/// Sizes follow Apple's default Dynamic Type sizes; line heights are about
/// 1.5 times the size because Arabic needs room for dots and marks.
/// Weights 400 to 700 only. Nothing is smaller than 11.
///
/// Material slot -> design style:
///   displaySmall large-title 34 · headlineLarge title-1 28 ·
///   headlineMedium title-2 22 · headlineSmall title-3 20 ·
///   titleLarge headline 17 · titleMedium 16 semibold · titleSmall 15 semibold ·
///   bodyLarge body 17 · bodyMedium subheadline 15 · bodySmall footnote 13 ·
///   labelLarge button 17 · labelMedium 13 semibold · labelSmall caption-1 12
abstract class AppTextTheme {
  AppTextTheme._();

  /// Family name declared in pubspec.yaml.
  static const String fontFamily = 'IBMPlexSansArabic';

  /// Tab bar labels (caption-2).
  static const TextStyle caption2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static TextStyle _style(double size, double lineHeight, FontWeight weight, Color color) {
    return TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      color: color,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  /// [secondary] is slate in the light theme and ink with Increased Contrast.
  static TextTheme build({Color secondary = AppColors.slate}) {
    return TextTheme(
      displaySmall: _style(34, 48, FontWeight.w700, AppColors.ink),
      headlineLarge: _style(28, 40, FontWeight.w700, AppColors.ink),
      headlineMedium: _style(22, 32, FontWeight.w700, AppColors.ink),
      headlineSmall: _style(20, 30, FontWeight.w600, AppColors.ink),
      titleLarge: _style(17, 26, FontWeight.w600, AppColors.ink),
      titleMedium: _style(16, 24, FontWeight.w600, AppColors.ink),
      titleSmall: _style(15, 22, FontWeight.w600, AppColors.ink),
      bodyLarge: _style(17, 26, FontWeight.w400, AppColors.ink),
      bodyMedium: _style(15, 22, FontWeight.w400, secondary),
      bodySmall: _style(13, 20, FontWeight.w400, secondary),
      labelLarge: _style(17, 26, FontWeight.w600, AppColors.ink),
      labelMedium: _style(13, 20, FontWeight.w600, AppColors.ink),
      labelSmall: _style(12, 18, FontWeight.w500, secondary),
    );
  }

  static final TextTheme textTheme = build();
}
