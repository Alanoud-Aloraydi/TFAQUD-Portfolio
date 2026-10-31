import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_component_themes.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// The TFAQUD theme (design system "TFAQUD"): light only, plus the variant the
/// app uses when iOS Increase Contrast is on.
///
/// [ColorScheme.primary] is ink, not leaf: Material paints text, icons and
/// selection marks in primary, and leaf is not a text color. The leaf fill of
/// the primary action comes from the filled button theme.
abstract class AppTheme {
  AppTheme._();

  static ColorScheme _colorScheme(AppTokens tokens) {
    return ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.surface,
      primaryContainer: AppColors.leafTint,
      onPrimaryContainer: AppColors.ink,
      secondary: AppColors.slate,
      onSecondary: AppColors.surface,
      secondaryContainer: AppColors.leaf,
      onSecondaryContainer: AppColors.ink,
      tertiary: AppColors.honey,
      onTertiary: AppColors.ink,
      error: AppColors.error,
      onError: AppColors.surface,
      // No tinted status backgrounds: a status is its icon and its word.
      errorContainer: AppColors.canvas,
      onErrorContainer: tokens.errorText,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      onSurfaceVariant: tokens.textSecondary,
      surfaceContainerLowest: AppColors.surface,
      surfaceContainerLow: AppColors.canvas,
      surfaceContainer: AppColors.canvas,
      surfaceContainerHigh: AppColors.canvas,
      surfaceContainerHighest: AppColors.canvas,
      outline: tokens.borderControl,
      outlineVariant: AppColors.line,
      shadow: AppColors.ink,
      scrim: AppColors.scrim,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.surface,
      inversePrimary: AppColors.leaf,
      surfaceTint: Colors.transparent,
    );
  }

  static ThemeData _build(AppTokens tokens) {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextTheme.fontFamily,
      colorScheme: _colorScheme(tokens),
      scaffoldBackgroundColor: AppColors.canvas,
      canvasColor: AppColors.canvas,
      textTheme: AppTextTheme.build(secondary: tokens.textSecondary),
      extensions: <ThemeExtension<dynamic>>[tokens],
      filledButtonTheme: AppComponentThemes.filledButton(tokens),
      outlinedButtonTheme: AppComponentThemes.outlinedButton(tokens),
      textButtonTheme: AppComponentThemes.textButton(tokens),
      iconButtonTheme: AppComponentThemes.iconButton,
      inputDecorationTheme: AppComponentThemes.inputDecoration(tokens),
      chipTheme: AppComponentThemes.chip(tokens),
      cardTheme: AppComponentThemes.card,
      dialogTheme: AppComponentThemes.dialog,
      bottomSheetTheme: AppComponentThemes.bottomSheet,
      dividerTheme: AppComponentThemes.divider,
      appBarTheme: AppComponentThemes.appBar,
      floatingActionButtonTheme: AppComponentThemes.fab,
      progressIndicatorTheme: AppComponentThemes.progress,
      snackBarTheme: AppComponentThemes.snackBar,
      listTileTheme: AppComponentThemes.listTile(tokens),
      checkboxTheme: AppComponentThemes.checkbox,
      radioTheme: AppComponentThemes.radio,
      // iOS shows a press as a short dim, not a ripple.
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x14202734),
    );
  }

  static final ThemeData lightTheme = _build(AppTokens.light);

  /// Used by MaterialApp when iOS Increase Contrast is on: secondary text and
  /// status words turn ink, control borders turn slate.
  static final ThemeData highContrastTheme = _build(AppTokens.contrast);
}
