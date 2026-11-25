import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Tokens of the normal appearance.
const AppTokens appTokensLight = AppTokens(
  textSecondary: AppSemanticColors.textSupporting,
  focus: AppSemanticColors.textSupporting,
  borderControl: AppSemanticColors.borderControlBase,
  success: AppSemanticColors.statusSuccess,
  successText: AppSemanticColors.statusSuccess,
  warning: AppSemanticColors.statusWarning,
  warningText: AppSemanticColors.statusWarning,
  error: AppSemanticColors.statusError,
  errorText: AppSemanticColors.statusError,
  infoText: AppSemanticColors.statusInfo,
  glassBorder: AppSemanticColors.surfaceContent,
);

/// Tokens with iOS Increase Contrast on.
const AppTokens appTokensContrast = AppTokens(
  textSecondary: AppSemanticColors.textPrimary,
  focus: AppSemanticColors.textSupporting,
  borderControl: AppSemanticColors.textSupporting,
  success: AppSemanticColors.statusSuccess,
  successText: AppSemanticColors.textPrimary,
  warning: AppSemanticColors.statusWarning,
  warningText: AppSemanticColors.textPrimary,
  error: AppSemanticColors.statusError,
  errorText: AppSemanticColors.textPrimary,
  infoText: AppSemanticColors.textPrimary,
  glassBorder: AppSemanticColors.textSupporting,
);

/// Blends two token sets, as ThemeExtension.lerp does.
AppTokens lerpAppTokens(AppTokens a, AppTokens b, double t) {
  return AppTokens(
    textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
    focus: Color.lerp(a.focus, b.focus, t)!,
    borderControl: Color.lerp(a.borderControl, b.borderControl, t)!,
    success: Color.lerp(a.success, b.success, t)!,
    successText: Color.lerp(a.successText, b.successText, t)!,
    warning: Color.lerp(a.warning, b.warning, t)!,
    warningText: Color.lerp(a.warningText, b.warningText, t)!,
    error: Color.lerp(a.error, b.error, t)!,
    errorText: Color.lerp(a.errorText, b.errorText, t)!,
    infoText: Color.lerp(a.infoText, b.infoText, t)!,
    glassBorder: Color.lerp(a.glassBorder, b.glassBorder, t)!,
  );
}

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
