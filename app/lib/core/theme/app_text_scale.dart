import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:flutter/material.dart';

TextStyle _style(
  double size,
  double lineHeight,
  FontWeight weight,
  Color color,
) {
  return TextStyle(
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    color: color,
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// [secondary] is slate in the light theme and ink with Increased Contrast.
TextTheme buildAppTextScale({
  Color secondary = AppSemanticColors.textSupporting,
}) {
  return TextTheme(
    displaySmall: _style(
      34,
      48,
      FontWeight.w700,
      AppSemanticColors.textPrimary,
    ),
    headlineLarge: _style(
      22,
      32,
      FontWeight.w700,
      AppSemanticColors.textPrimary,
    ),
    headlineMedium: _style(
      22,
      32,
      FontWeight.w700,
      AppSemanticColors.textPrimary,
    ),
    headlineSmall: _style(
      22,
      32,
      FontWeight.w600,
      AppSemanticColors.textPrimary,
    ),
    titleLarge: _style(17, 28, FontWeight.w600, AppSemanticColors.textPrimary),
    titleMedium: _style(17, 28, FontWeight.w600, AppSemanticColors.textPrimary),
    titleSmall: _style(15, 24, FontWeight.w600, AppSemanticColors.textPrimary),
    bodyLarge: _style(17, 28, FontWeight.w400, AppSemanticColors.textPrimary),
    bodyMedium: _style(15, 24, FontWeight.w400, secondary),
    bodySmall: _style(13, 20, FontWeight.w400, secondary),
    labelLarge: _style(17, 28, FontWeight.w600, AppSemanticColors.textPrimary),
    labelMedium: _style(13, 20, FontWeight.w600, AppSemanticColors.textPrimary),
    labelSmall: _style(13, 20, FontWeight.w500, secondary),
  );
}
