import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared navigation themes for the current application appearance.
abstract class AppNavigationThemes {
  AppNavigationThemes._();

  /// Bars carry no background or divider: glass controls float on canvas.
  static final AppBarThemeData appBar = AppBarThemeData(
    backgroundColor: AppColors.canvas,
    foregroundColor: AppColors.ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    // Dark status bar text (time, signal, battery) on the light canvas. A
    // transparent bar would otherwise get white text that cannot be seen.
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: TextStyle(
      fontFamily: AppTextTheme.fontFamily,
      color: AppColors.ink,
      fontSize: 17,
      height: 28 / 17,
      fontWeight: FontWeight.w600,
    ),
  );
}
