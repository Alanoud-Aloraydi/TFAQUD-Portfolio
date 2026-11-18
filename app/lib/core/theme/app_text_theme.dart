import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_scale.dart';
import 'package:flutter/material.dart';

/// Type scale of the design system, set in IBM Plex Sans Arabic: five
/// sizes only, so every page reads as one system (34 · 22 · 17 · 15 · 13).
/// Line heights sit on the 4-point grid (48 · 32 · 28 · 24 · 20), about 1.5
/// to 1.6 times the size, because Arabic needs room for dots and marks.
/// Weights 400 to 700 only. Nothing is smaller than 13.
///
/// Material slot -> design style:
///   displaySmall large-title 34 ·
///   headlineLarge / headlineMedium title 22 bold · headlineSmall title 22
///   semibold (sections, sheets, cards) ·
///   titleLarge / titleMedium headline 17 semibold · titleSmall 15 semibold ·
///   bodyLarge body 17 · bodyMedium subheadline 15 · bodySmall footnote 13 ·
///   labelLarge button 17 · labelMedium 13 semibold · labelSmall 13 medium
abstract class AppTextTheme {
  AppTextTheme._();

  /// Family name declared in pubspec.yaml.
  static const String fontFamily = 'IBMPlexSansArabic';

  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;

  /// Typography shared by date and time wheels.
  static const TextStyle picker = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w400,
    color: AppSemanticColors.textPrimary,
  );

  /// The five sizes of the scale, largest first.
  static const List<double> sizes = <double>[34, 22, 17, 15, 13];

  /// [secondary] is slate in the light theme and ink with Increased Contrast.
  static TextTheme build({Color secondary = AppSemanticColors.textSupporting}) {
    return buildAppTextScale(secondary: secondary);
  }

  static final TextTheme textTheme = build();
}
