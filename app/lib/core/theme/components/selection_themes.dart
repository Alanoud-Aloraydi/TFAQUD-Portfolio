import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Shared selection themes for the current application appearance.
abstract class AppSelectionThemes {
  AppSelectionThemes._();

  static ChipThemeData chip(AppTokens tokens) {
    return ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.leafTint,
      checkmarkColor: AppColors.ink,
      disabledColor: AppColors.line,
      side: BorderSide(color: tokens.borderControl),
      shape: const StadiumBorder(),
      showCheckmark: true,
      // The chip theme's label style replaces Material's default, so it must
      // name the app font itself; without it the options of «الأمراض
      // المزمنة» and «الحساسية» showed in the system font.
      labelStyle: const TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: AppColors.ink,
        fontSize: 15,
        height: 24 / 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  static final CheckboxThemeData checkbox = CheckboxThemeData(
    checkColor: WidgetStatePropertyAll<Color>(AppColors.surface),
    side: BorderSide(color: AppColors.stone, width: 1.5),
  );

  static final RadioThemeData radio = RadioThemeData(
    fillColor: WidgetStatePropertyAll<Color>(AppColors.ink),
  );
}
