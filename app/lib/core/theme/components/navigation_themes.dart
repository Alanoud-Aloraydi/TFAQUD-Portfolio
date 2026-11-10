import 'package:app/core/theme/app_semantic_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared navigation themes for the current application appearance.
abstract class AppNavigationThemes {
  AppNavigationThemes._();

  /// The phone's status bar over the app's light pages, on every page (the
  /// root of `MainApp`, the app bars, the intro): transparent, with dark
  /// time, signal and battery (`statusBarIconBrightness` on Android,
  /// `statusBarBrightness` on iOS).
  ///
  /// It leaves the Android navigation bar to the native theme (`NormalTheme`
  /// in `values-v27/styles.xml`): [SystemUiOverlayStyle.dark] would paint it
  /// black on every page with an app bar, and dark buttons on a light bar
  /// cannot be asked for below Android 8.1, where they would turn invisible.
  static const SystemUiOverlayStyle systemBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  /// Bars carry no background or divider: glass controls float on canvas.
  static final AppBarThemeData appBar = AppBarThemeData(
    backgroundColor: AppSemanticColors.background,
    foregroundColor: AppSemanticColors.textPrimary,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    systemOverlayStyle: systemBars,
    titleTextStyle: TextStyle(
      fontFamily: AppTextTheme.fontFamily,
      color: AppSemanticColors.textPrimary,
      fontSize: 17,
      height: 28 / 17,
      fontWeight: FontWeight.w600,
    ),
  );
}
