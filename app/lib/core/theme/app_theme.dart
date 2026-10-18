import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

abstract class AppTheme {
  AppTheme._();

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.brand,
    onPrimary: AppColors.onBrand,
    primaryContainer: AppColors.brandTint,
    onPrimaryContainer: AppColors.brand,
    secondary: AppColors.ink2,
    onSecondary: AppColors.surface,
    secondaryContainer: AppColors.sunken,
    onSecondaryContainer: AppColors.ink,
    error: AppColors.danger,
    onError: AppColors.surface,
    errorContainer: AppColors.dangerTint,
    onErrorContainer: AppColors.dangerInk,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    onSurfaceVariant: AppColors.ink3,
    outline: AppColors.fieldBorder,
    outlineVariant: AppColors.line,
    scrim: AppColors.scrim,
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: AppTextTheme.textTheme,
    extensions: const <ThemeExtension<dynamic>>[AppTokens.light],
    filledButtonTheme: AppComponentThemes.filledButton,
    outlinedButtonTheme: AppComponentThemes.outlinedButton,
    textButtonTheme: AppComponentThemes.textButton,
    inputDecorationTheme: AppComponentThemes.inputDecoration,
    chipTheme: AppComponentThemes.chip,
    cardTheme: AppComponentThemes.card,
    dialogTheme: AppComponentThemes.dialog,
    bottomSheetTheme: AppComponentThemes.bottomSheet,
    dividerTheme: AppComponentThemes.divider,
    appBarTheme: AppComponentThemes.appBar,
    floatingActionButtonTheme: AppComponentThemes.fab,
  );
}
