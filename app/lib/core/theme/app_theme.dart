import 'package:app/core/theme/components/surface_themes.dart';
import 'package:app/core/theme/components/selection_themes.dart';
import 'package:app/core/theme/components/navigation_themes.dart';
import 'package:app/core/theme/components/field_themes.dart';
import 'package:app/core/theme/components/feedback_themes.dart';
import 'package:app/core/theme/components/button_themes.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The TFAQUD theme (design system "TFAQUD"): light only, plus the variant the
/// app uses when iOS Increase Contrast is on.
///
/// [ColorScheme.primary] is ink: Material paints text, icons, selection marks
/// and the primary action in it, with white on top.
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
      secondaryContainer: AppColors.leafTint,
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
      inversePrimary: AppColors.honey,
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
      filledButtonTheme: AppButtonThemes.filledButton(tokens),
      outlinedButtonTheme: AppButtonThemes.outlinedButton(tokens),
      textButtonTheme: AppButtonThemes.textButton(tokens),
      iconButtonTheme: AppButtonThemes.iconButton,
      inputDecorationTheme: AppFieldThemes.inputDecoration(tokens),
      chipTheme: AppSelectionThemes.chip(tokens),
      cardTheme: AppSurfaceThemes.card,
      dialogTheme: AppSurfaceThemes.dialog,
      bottomSheetTheme: AppSurfaceThemes.bottomSheet,
      dividerTheme: AppSurfaceThemes.divider,
      appBarTheme: AppNavigationThemes.appBar,
      floatingActionButtonTheme: AppButtonThemes.fab,
      progressIndicatorTheme: AppFeedbackThemes.progress,
      snackBarTheme: AppFeedbackThemes.snackBar,
      listTileTheme: AppSurfaceThemes.listTile(tokens),
      checkboxTheme: AppSelectionThemes.checkbox,
      radioTheme: AppSelectionThemes.radio,
      // iOS shows a press as a short dim, not a ripple.
      splashFactory: NoSplash.splashFactory,
      // iOS push and pop (with the swipe back) on every platform, the web
      // preview included, so testing in Chrome feels like the phone.
      pageTransitionsTheme: _iosTransitions,
      // The back and close buttons Material draws by itself (the app bar of
      // a medicine's pages) use Apple's symbols, as every icon in the app.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) =>
            const Icon(CupertinoIcons.back),
        closeButtonIconBuilder: (BuildContext context) =>
            const Icon(CupertinoIcons.xmark),
      ),
      // Cupertino widgets (pickers, action sheets, dialogs) use the app font
      // and ink instead of the system blue.
      cupertinoOverrideTheme: const NoDefaultCupertinoThemeData(
        primaryColor: AppColors.ink,
        scaffoldBackgroundColor: AppColors.canvas,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppColors.ink,
          pickerTextStyle: AppTextTheme.picker,
          dateTimePickerTextStyle: AppTextTheme.picker,
        ),
      ),
      highlightColor: const Color(0x14202734),
    );
  }

  static const PageTransitionsTheme _iosTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static final ThemeData lightTheme = _build(AppTokens.light);

  /// Used by MaterialApp when iOS Increase Contrast is on: secondary text and
  /// status words turn ink, control borders turn slate.
  static final ThemeData highContrastTheme = _build(AppTokens.contrast);
}
