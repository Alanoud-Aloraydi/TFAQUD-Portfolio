import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

ColorScheme buildAppColorScheme(AppTokens tokens) {
  return ColorScheme(
    brightness: Brightness.light,
    primary: AppSemanticColors.textPrimary,
    onPrimary: AppSemanticColors.surfaceContent,
    primaryContainer: AppSemanticColors.selectedSurface,
    onPrimaryContainer: AppSemanticColors.textPrimary,
    secondary: AppSemanticColors.textSupporting,
    onSecondary: AppSemanticColors.surfaceContent,
    secondaryContainer: AppSemanticColors.selectedSurface,
    onSecondaryContainer: AppSemanticColors.textPrimary,
    tertiary: AppSemanticColors.accentWarm,
    onTertiary: AppSemanticColors.textPrimary,
    error: AppSemanticColors.statusError,
    onError: AppSemanticColors.surfaceContent,
    // No tinted status backgrounds: a status is its icon and its word.
    errorContainer: AppSemanticColors.background,
    onErrorContainer: tokens.errorText,
    surface: AppSemanticColors.surfaceContent,
    onSurface: AppSemanticColors.textPrimary,
    onSurfaceVariant: tokens.textSecondary,
    surfaceContainerLowest: AppSemanticColors.surfaceContent,
    surfaceContainerLow: AppSemanticColors.background,
    surfaceContainer: AppSemanticColors.background,
    surfaceContainerHigh: AppSemanticColors.background,
    surfaceContainerHighest: AppSemanticColors.background,
    outline: tokens.borderControl,
    outlineVariant: AppSemanticColors.borderSubtle,
    shadow: AppSemanticColors.textPrimary,
    scrim: AppSemanticColors.overlayScrim,
    inverseSurface: AppSemanticColors.textPrimary,
    onInverseSurface: AppSemanticColors.surfaceContent,
    inversePrimary: AppSemanticColors.accentWarm,
    surfaceTint: Colors.transparent,
  );
}
