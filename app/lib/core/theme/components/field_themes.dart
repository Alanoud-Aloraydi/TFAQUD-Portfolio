import 'package:app/core/theme/foundations/app_radius.dart';
import 'package:app/core/constants/app_colors.dart';
import 'package:app/core/theme/app_text_theme.dart';
import 'package:app/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Shared field themes for the current application appearance.
abstract class AppFieldThemes {
  AppFieldThemes._();

  static OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.s),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Fields: 52 high (a 28 line, 12 above and below), radius-s, a control
  /// border; focus and error are 2px.
  static InputDecorationThemeData inputDecoration(AppTokens tokens) {
    return InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
      border: _outline(tokens.borderControl),
      enabledBorder: _outline(tokens.borderControl),
      disabledBorder: _outline(AppColors.line),
      focusedBorder: _outline(tokens.focus, 2),
      errorBorder: _outline(tokens.error, 2),
      focusedErrorBorder: _outline(tokens.error, 2),
      // Every style names the app font: a component style that leaves it out
      // can fall back to the system font.
      hintStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.textSecondary,
        fontSize: 17,
        height: 28 / 17,
      ),
      labelStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.textSecondary,
        fontSize: 15,
        height: 24 / 15,
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: AppColors.ink,
        fontSize: 15,
        height: 24 / 15,
      ),
      helperStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.textSecondary,
        fontSize: 13,
        height: 20 / 13,
      ),
      errorStyle: TextStyle(
        fontFamily: AppTextTheme.fontFamily,
        color: tokens.errorText,
        fontSize: 13,
        height: 20 / 13,
      ),
      prefixIconColor: tokens.textSecondary,
      suffixIconColor: tokens.textSecondary,
    );
  }
}
